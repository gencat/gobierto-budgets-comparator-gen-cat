namespace :gobierto_budgets do
  namespace :debt do
    DEBT_INDEX = GobiertoBudgets::SearchEngineConfiguration::Data.index
    DEBT_TYPE = GobiertoBudgets::SearchEngineConfiguration::Data.type_debt

    def create_debt_mapping(index, type)
      m = GobiertoBudgets::SearchEngine.client.indices.get_mapping index: index, type: type
      return unless m.empty?

      # Document identifier: <ine_code>/<year>
      #
      # Example: 28079/2015
      # Example: 28079/2015
      GobiertoBudgets::SearchEngine.client.indices.put_mapping index: index, type: type, body: {
        type.to_sym => {
          properties: {
            ine_code:              { type: 'integer', index: 'not_analyzed' },
            province_id:           { type: 'integer', index: 'not_analyzed' },
            autonomy_id:           { type: 'integer', index: 'not_analyzed' },
            year:                  { type: 'integer', index: 'not_analyzed' },
            value:                 { type: 'double', index: 'not_analyzed' }
          }
        }
      }
    end

    def import_debt(file_path, year)
      pbar = ProgressBar.new("debt-#{year}", INE::Places::Place.all.length)

      problems = []
      CSV.foreach(file_path) do |row|
        pbar.inc

        id = row[1] + format('%.3i', row[2].to_i)
        next if id.nil?
        value = row[4].tr('.','').to_f
        place = INE::Places::Place.find id
        if place.nil?
          problems << row
          next
        end

        data = {
          ine_code: place.id.to_i, province_id: place.province.id.to_i,
          autonomy_id: place.province.autonomous_region.id.to_i, year: year,
          value: value
        }

        id = [place.id,year].join("/")

        GobiertoBudgets::SearchEngine.client.index index: DEBT_INDEX, type: DEBT_TYPE, id: id, body: data
      end

      pbar.finish
      puts "Problems importing debt with: " if problems.any?
      problems.each do |row|
        puts "  #{row.join(',')}"
      end
    end

    desc 'Reset ElasticSearch'
    task :reset => :environment do
      if GobiertoBudgets::SearchEngine.client.indices.exists? index: DEBT_INDEX
        puts "- Deleting #{DEBT_INDEX} index"
        GobiertoBudgets::SearchEngine.client.indices.delete index: DEBT_INDEX
      end
    end

    desc 'Create mappings'
    task :create => :environment do
      unless GobiertoBudgets::SearchEngine.client.indices.exists? index: DEBT_INDEX
        puts "- Creating index #{DEBT_INDEX}"
        GobiertoBudgets::SearchEngine.client.indices.create index: DEBT_INDEX, body: {
          settings: {
            # Allow 100_000 results per query
            index: { max_result_window: 100_000 }
          }
        }
      end

      puts "- Creating #{DEBT_INDEX} > #{DEBT_TYPE}"
      create_debt_mapping(DEBT_INDEX, DEBT_TYPE)
    end

    desc "Import debt from pc-axis file into ElasticSearch. Example rake gobierto_budgets:debt:import[2014,'db/data/debt/debt-2014.csv']"
    task :import, [:year, :file_path] => :environment do |t, args|
      if m = args[:year].match(/\A\d{4}\z/)
        year = m[0].to_i
      end

      file_path = args[:file_path]
      raise "Invalid year #{args[:year]}" if year.blank?
      raise "Invalid file #{file_path}" if file_path.blank? || !File.file?(file_path)

      import_debt(file_path, year)
    end
  end
end
