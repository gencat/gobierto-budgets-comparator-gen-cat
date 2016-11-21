namespace :gobierto_budgets do
  namespace :budget_categories do
    def create_categories_mapping
      m = GobiertoBudgets::SearchEngine.client.indices.get_mapping index: GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.index, type: GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.type
      return unless m.empty?

      # document id: `<area_name>/<code>/<kind>`. Example: `economic/G`
      GobiertoBudgets::SearchEngine.client.indices.put_mapping index: GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.index, type: GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.type, body: {
        GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.type.to_sym => {
          properties: {
            area:                  { type: 'string', index: 'not_analyzed'  },
            code:                  { type: 'string', index: 'not_analyzed'  },
            name:                  { type: 'string', index: 'not_analyzed'  },
            parent_code:           { type: 'string', index: 'not_analyzed'  },
            level:                 { type: 'integer', index: 'not_analyzed' },
            kind:                  { type: 'string', index: 'not_analyzed'  } # income I / expense G
          }
        }
      }
    end

    def create_db_connection(db_name)
      ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations[Rails.env].merge('database' => db_name)
      ActiveRecord::Base.connection
    end

    def import_categories(db_name)
      db = create_db_connection(db_name)

      (2010..2015).to_a.reverse.each do |year|
        import_economic_categories(db, year)
        import_functional_categories(db, year)
      end
    end

    def import_economic_categories(db, year)
      first_level_dict = {
        'G' => {"2"=>"Gastos en bienes corrientes y servicios", "3"=>"Gastos financieros", "4"=>"Transferencias corrientes", "6"=>"Inversiones reales", "7"=>"Transferencias de capital", "8"=>"Activos financieros", "9"=>"Pasivos financieros", "1"=>"Gastos de personal", "5"=>"Fondo de contingencia y otros imprevistos"},
        'I' =>  {"1"=>"Impuestos directos", "2"=>"Impuestos indirectos", "3"=>"Tasas y otros ingresos", "4"=>"Transferencias corrientes", "5"=>"Ingresos patrimoniales", "6"=>"Enajenación de inversiones reales", "7"=>"Transferencias de capital", "8"=>"Activos financieros", "9"=>"Pasivos financieros"}
      }

      table_name = "tb_cuentasEconomica_#{year}"
      sql = %Q{SELECT * from "#{table_name}"}
      all_rows = db.execute(sql)
      pbar = ProgressBar.new("econ-#{year}", all_rows.num_tuples)
      all_rows.each do |row|
        pbar.inc
        code = row['cdcta']
        level = row['cdcta'].length
        parent_code = row['cdcta'][0..-2]
        if code.include?('.')
          code = code.tr('.','-')
          level = 4
          parent_code = code.split('-').first
        end

        query = {
          area: 'economic',
          code: code,
          name: code.length == 1 ? first_level_dict[row['tipreig']][code] : row['nombre'].tr('.',''),
          parent_code: parent_code,
          level: level,
          kind: row['tipreig']
        }

        id = ['economic',code,row['tipreig']].join('/')
        GobiertoBudgets::SearchEngine.client.index index: GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.index, type: GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.type, id: id, body: query
      end
      pbar.finish
    end

    def import_functional_categories(db, year)
      first_level_dict = {
        "3"=>"Producción de bienes públicos de carácter preferente", "0"=>"Deuda pública",
        "2"=>"Actuaciones de protección y promoción social", "9"=>"Actuaciones de carácter general",
        "4"=>"Actuaciones de carácter económico", "1"=>"Servicios públicos básicos"
      }
      table_name = "tb_cuentasProgramas_#{year}"

      sql = %Q{select * from "#{table_name}"}
      all_rows = db.execute(sql)
      pbar = ProgressBar.new("func-#{year}", all_rows.num_tuples)
      all_rows.each do |row|
        pbar.inc
        code = row['cdfgr']
        level = row['cdfgr'].length
        parent_code = row['cdfgr'][0..-2]
        if code.include?('.')
          code = code.tr('.','-')
          level = 4
          parent_code = code.split('-').first
        end

        query = {
          area: 'functional',
          code: code,
          name: code.length == 1 ? first_level_dict[code] : row['nombre'].tr('.',''),
          parent_code: parent_code,
          level: level,
          kind: 'G'
        }

        # There's a bug in the government data
        if code.to_i == 91
          query[:name] = "Órganos de gobierno"
        end

        id = ['functional',code,'G'].join('/')

        GobiertoBudgets::SearchEngine.client.index index: GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.index, type: GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.type, id: id,  body: query
      end
      pbar.finish
    end

    desc 'Reset ElasticSearch'
    task :reset => :environment do
      if GobiertoBudgets::SearchEngine.client.indices.exists? index: GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.index
        puts "- Deleting #{GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.index}..."
        GobiertoBudgets::SearchEngine.client.indices.delete index: GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.index
      end
    end

    desc 'Create mappings'
    task :create => :environment do
      unless GobiertoBudgets::SearchEngine.client.indices.exists? index: GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.index
        puts "- Creating index #{GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.index}"
        GobiertoBudgets::SearchEngine.client.indices.create index: GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.index, body: {
          settings: {
            # Allow 100_000 results per query
            index: { max_result_window: 100_000 }
          }
        }
      end

      puts "- Creating #{GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.index} #{GobiertoBudgets::SearchEngineConfiguration::BudgetCategories.type}"
      create_categories_mapping
    end

    desc "Import categories. Example: rake budget_categories:import['db_name']"
    task :import, [:db_name] => :environment do |t, args|
      db_name = args[:db_name]
      raise "Missing db name" if db_name.blank?

      self.send("import_categories", db_name)
    end
  end
end
