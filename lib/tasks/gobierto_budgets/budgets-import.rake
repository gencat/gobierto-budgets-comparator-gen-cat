namespace :gobierto_budgets do
  namespace :budgets do
    BUDGETS_INDEXES = [GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_executed,
                       GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_executed_series, GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast_updated]
    BUDGETS_TYPES = ['economic', 'functional', 'custom']
    PLACES_SETS = {
      ine: INE::Places::Place.all,
      deputation_eu: [
        OpenStruct.new(id: "48000DD000", province_id: 48, autonomous_region_id: 16, name: "Diputación Foral de Vizcaya", custom_id: "deputation_eu"),
        OpenStruct.new(id: "01000DD000", province_id: 1, autonomous_region_id: 16, name: "Diputación Foral de Alava", custom_id: "deputation_eu"),
        OpenStruct.new(id: "20000DD000", province_id: 20, autonomous_region_id: 16, name: "Diputación Foral de Guipúzcoa", custom_id: "deputation_eu")
      ]
    }

    def create_budgets_mapping(index, type)
      m = GobiertoBudgets::SearchEngine.client.indices.get_mapping index: index, type: type
      return unless m.empty?

      puts "  - Creating #{index} #{type}"
      # BUDGETS_INDEX: budgets-forecast // budgets-execution
      # BUDGETS_TYPE: economic // functional // custom
      #
      # Document identifier: <ine_code>/<year>/<code>/<kind>
      #
      # Example: 28079/2015/210.00/0
      # Example: 28079/2015/210.00/1
      GobiertoBudgets::SearchEngine.client.indices.put_mapping index: index, type: type, body: {
        type.to_sym => {
          properties: {
            ine_code:              { type: 'integer', index: 'not_analyzed' },
            organization_id:       { type: 'string',  index: 'not_analyzed' },
            year:                  { type: 'integer', index: 'not_analyzed' },
            amount:                { type: 'double', index: 'not_analyzed'  },
            code:                  { type: 'string', index: 'not_analyzed'  },
            parent_code:           { type: 'string', index: 'not_analyzed'  },
            functional_code:       { type: 'string', index: 'not_analyzed'  },
            custom_code:           { type: 'string', index: 'not_analyzed'  },
            level:                 { type: 'integer', index: 'not_analyzed' },
            kind:                  { type: 'string', index: 'not_analyzed'  }, # income I / expense G
            province_id:           { type: 'integer', index: 'not_analyzed' },
            autonomy_id:           { type: 'integer', index: 'not_analyzed' },
            amount_per_inhabitant: { type: 'double', index: 'not_analyzed'  }
          }
        }
      }
    end

    def create_budgets_execution_series_mapping(index, type)
      m = GobiertoBudgets::SearchEngine.client.indices.get_mapping index: index, type: type
      return unless m.empty?

      puts "  - Creating #{index} #{type}"
      # BUDGETS_INDEX: gobierto-budgets-execution-series
      # BUDGETS_TYPE: economic // functional // custom
      #
      # Document identifier: <ine_code>/<code>/<kind>
      # Example: 28079/101/I
      GobiertoBudgets::SearchEngine.client.indices.put_mapping index: index, type: type, body: {
        type.to_sym => {
          properties: {
            ine_code:       { type: 'integer', index: 'not_analyzed' },
            organization_id:       { type: 'string',  index: 'not_analyzed' },
            kind:           { type: 'string',  index: 'not_analyzed' },  # income I / expense G
            code:           { type: 'string',  index: 'not_analyzed' },
            values: {
              properties: {
                date:       { type: 'string',  index: 'not_analyzed' },
                amount:     { type: 'double',  index: 'not_analyzed' }
              }
            }
          }
        }
      }
    end

    def create_db_connection(db_name)
      ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations[Rails.env].merge('database' => db_name)
      ActiveRecord::Base.connection
    end

    def population(id, year)
      response = GobiertoBudgets::SearchEngine.client.get index: 'data', type: 'population', id: "#{id}/#{year}"
      response['_source']['value']
    rescue
      nil
    end

    def import_functional_budgets(db_name, index, year, destination_year, opts = {})
      db = create_db_connection(db_name)

      places_key = opts.fetch(:place_type, :ine)
      places = PLACES_SETS[places_key]

      places.each do |place|
        place_attrs = place_attributes(place)

        place_attrs.each do |key, value|
          next if ENV[key].present? && value != ENV[key].to_i
        end

        next if ENV["custom_place_id"].present? && place.try(:custom_place_id) != ENV["custom_place_id"]

        pop = if place_attrs["place_id"].present?
                population(place.id, destination_year) || population(place.id, destination_year - 1) || population(place.id, destination_year - 2)
              else
                nil
              end

        if place_attrs["place_id"].present? && pop.nil?
          puts "- Skipping #{place.id} #{place.name} because population data is missing for #{destination_year} and #{destination_year-1}"
          next
        end

        base_data = {
          ine_code: place_attrs["place_id"],
          province_id: place_attrs["province_id"],
          autonomy_id: place_attrs["autonomous_region_id"],
          organization_id: place.id.to_s,
          year: destination_year,
          population: pop
        }

        sql = <<-SQL
SELECT tb_funcional_#{year}.cdfgr as code, sum(tb_funcional_#{year}.importe) as amount
FROM tb_funcional_#{year}
INNER JOIN "tb_inventario_#{year}" ON tb_inventario_#{year}.idente = tb_funcional_#{year}.idente AND tb_inventario_#{year}.codente = '#{place_code(place)}'
GROUP BY tb_funcional_#{year}.cdfgr
SQL

        index_request_body = []
        db.execute(sql).each do |row|
          code = row['code']
          level = row['code'].length
          parent_code = row['code'][0..-2]
          if code.include?('.')
            code = code.tr('.','-')
            level = 4
            parent_code = code.split('-').first
          end
          data = base_data.merge({
            amount: row['amount'].to_f.round(2), code: code,
            level: level, kind: 'G',
            amount_per_inhabitant: pop.presence && (row['amount'].to_f / pop).round(2),
            parent_code: parent_code
          })

          id = [place.id,destination_year,code,'G'].join("/")
          index_request_body << {index: {_id: id, data: data}}
        end
        next if index_request_body.empty?

        GobiertoBudgets::SearchEngine.client.bulk index: index, type: 'functional', body: index_request_body

        # Import economic sublevels
        sql = <<-SQL
SELECT tb_funcional_#{year}.cdcta as code, tb_funcional_#{year}.cdfgr as functional_code, tb_funcional_#{year}.importe as amount
FROM tb_funcional_#{year}
INNER JOIN "tb_inventario_#{year}" ON tb_inventario_#{year}.idente = tb_funcional_#{year}.idente AND tb_inventario_#{year}.codente = '#{place_code(place)}'
SQL

        index_request_body = []
        db.execute(sql).each do |row|
          code = row['code']
          functional_code = row['functional_code']
          if functional_code.include?('.')
            functional_code = functional_code.tr('.','-')
          end
          data = base_data.merge({
            amount: row['amount'].to_f.round(2), code: code,
            functional_code: functional_code, kind: 'G',
            amount_per_inhabitant:  pop.presence && (row['amount'].to_f / pop).round(2)
          })

          id = [place.id,destination_year,"#{code}-#{functional_code}",'G'].join("/")
          index_request_body << {index: {_id: id, data: data}}
        end
        next if index_request_body.empty?

        GobiertoBudgets::SearchEngine.client.bulk index: index, type: 'economic', body: index_request_body
      end
    end

    def import_economic_budgets(db_name, index, year, destination_year, opts = {})
      db = create_db_connection(db_name)

      places_key = opts.fetch(:place_type, :ine)
      places = PLACES_SETS[places_key]

      places.each do |place|
        place_attrs = place_attributes(place)

        place_attrs.each do |key, value|
          next if ENV[key].present? && value != ENV[key].to_i
        end

        next if ENV["custom_place_id"].present? && place.try(:custom_place_id) != ENV["custom_place_id"]

        pop = if place_attrs["place_id"].present?
                population(place.id, destination_year) || population(place.id, destination_year - 1) || population(place.id, destination_year - 2)
              else
                nil
              end

        if place_attrs["place_id"].present? && pop.nil?
          puts "- Skipping #{place.id} #{place.name} because population data is missing for #{destination_year} and #{destination_year-1}"
          next
        end

        base_data = {
          ine_code: place_attrs["place_id"],
          province_id: place_attrs["province_id"],
          autonomy_id: place_attrs["autonomous_region_id"],
          organization_id: place.id.to_s,
          year: destination_year,
          population: pop
        }

        amount_column = if index == GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast
                          'importe'
                        elsif index == GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_executed
                          'importer'
                        end

        sql = <<-SQL
SELECT tb_economica_#{year}.cdcta as code, tb_economica_#{year}.tipreig AS kind, tb_economica_#{year}.#{amount_column} as amount
FROM tb_economica_#{year}
INNER JOIN "tb_inventario_#{year}" ON tb_inventario_#{year}.idente = tb_economica_#{year}.idente AND tb_inventario_#{year}.codente = '#{place_code(place)}'
SQL

        index_request_body = []
        db.execute(sql).each do |row|
          code = row['code']
          level = row['code'].length
          parent_code = row['code'][0..-2]
          if code.include?('.')
            code = code.tr('.','-')
            level = 4
            parent_code = code.split('-').first
          end

          data = base_data.merge({
            amount: row['amount'].to_f.round(2), code: code,
            level: level, kind: row['kind'],
            amount_per_inhabitant:  pop.presence && (row['amount'].to_f / pop).round(2),
            parent_code: parent_code
          })

          id = [place.id,destination_year,code,row['kind']].join("/")
          index_request_body << {index: {_id: id, data: data}}
        end
        next if index_request_body.empty?

        GobiertoBudgets::SearchEngine.client.bulk index: index, type: 'economic', body: index_request_body
      end
    end

    def place_attributes(place)
      {
        "place_id" => numeric?(place.id) ? place.id.to_i : nil,
        "province_id" => place.try(:province_id) || place.province.id.to_i,
        "autonomous_region_id" => place.try(:autonomous_region_id) || place.province.autonomous_region.id.to_i
      }
    end

    def place_code(place)
      return place.id unless numeric?(place.id)

      "#{format("%.5i", place.id)}AA000"
    end

    def numeric?(value)
      value.is_a?(Numeric) || /\A\d+\z/.match?(value.to_s.strip)
    end

    desc 'Reset ElasticSearch'
    task :reset => :environment do
      BUDGETS_INDEXES.each do |index|
        if GobiertoBudgets::SearchEngine.client.indices.exists? index: index
          puts "- Deleting #{index}..."
          GobiertoBudgets::SearchEngine.client.indices.delete index: index
        end
      end
    end

    desc 'Create mappings'
    task :create => :environment do
      BUDGETS_INDEXES.each do |index|
        unless GobiertoBudgets::SearchEngine.client.indices.exists? index: index
          puts "- Creating index #{index}"
          GobiertoBudgets::SearchEngine.client.indices.create index: index, body: {
            settings: {
              # Allow 100_000 results per query
              index: { max_result_window: 100_000 }
            }
          }
        end

        BUDGETS_TYPES.each do |type|
          if index == GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_executed_series
            create_budgets_execution_series_mapping(index, type)
          else
            create_budgets_mapping(index, type)
          end
        end
      end
    end

    desc "Import budgets from database into ElasticSearch. Example bin/rails gobierto_budgets:budgets:import['budgets-dbname','budgets-execution','economic',2015] place_id=28079 province_id=3 autonomous_region_id=5"
    task :import, [:db_name, :index, :type, :year, :destination_year, :place_type] => :environment do |t, args|
      db_name = args[:db_name]
      index = args[:index] if BUDGETS_INDEXES.include?(args[:index])
      raise "Invalid index #{args[:index]}" if index.blank?
      type = args[:type] if BUDGETS_TYPES.include?(args[:type])
      raise "Invalid type #{args[:type]}" if type.blank?
      if m = args[:year].match(/\A\d{4}\z/)
        year = m[0].to_i
      end
      raise "Invalid year #{args[:year]}" if year.blank?

      if args[:destination_year].present? && m = args[:destination_year].match(/\A\d{4}\z/)
        destination_year = m[0].to_i
      else
        destination_year = year
      end

      opts = if (place_type = args[:place_type]&.to_sym).present?
               raise "Invalid place_type #{place_type}. Valid place types: #{PLACES_SETS.keys.join(", ")} " unless PLACES_SETS.keys.include?(place_type)

               { place_type: place_type }
             else
               {}
             end

      self.send("import_#{type}_budgets", db_name, index, year, destination_year, **opts)
    end
  end
end
