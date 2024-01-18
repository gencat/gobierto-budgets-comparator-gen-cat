namespace :gobierto_budgets do
  namespace :total_budget do
    TOTAL_BUDGET_INDEXES = [GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_forecast, GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_executed, GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_forecast_updated]

    def create_total_budget_mapping(index, type)
      m = GobiertoBudgets::SearchEngine.client.indices.get_mapping index: index, type: type
      return unless m.empty?

      puts "  - Creating #{index} > #{GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type}"
      # Document identifier: <ine_code>/<year>/<kind>
      #
      # Example: 28079/2015/I
      # Example: 28079/2015/G
      # Example: 28079/2014/G
      GobiertoBudgets::SearchEngine.client.indices.put_mapping index: index, type: type, body: {
        type.to_sym => {
          properties: {
            ine_code:                    { type: 'integer', index: 'not_analyzed' },
            organization_id:             { type: 'string',  index: 'not_analyzed' },
            province_id:                 { type: 'integer', index: 'not_analyzed' },
            autonomy_id:                 { type: 'integer', index: 'not_analyzed' },
            year:                        { type: 'integer', index: 'not_analyzed' },
            kind:                        { type: 'string', index: 'not_analyzed'  }, # income I / expense G
            total_budget:                { type: 'double',  index: 'not_analyzed' },
            total_budget_per_inhabitant: { type: 'double',  index: 'not_analyzed' }
          }
        }
      }
    end

    def get_data(index,place,year,kind,type=nil)
      # total budget in a place
      query = {
        query: {
          filtered: {
            query: {
              match_all: {}
            },
            filter: {
              bool: {
                must: [
                  {term: { ine_code: place.attributes["place_id"] }},
                  {term: { level: 1 }},
                  {term: { kind: kind }},
                  {term: { year: year }},
                  {term: { organization_id: place.id.to_s }},
                  {missing: { field: 'functional_code'}},
                  {missing: { field: 'custom_code'}}
                ].select { |condition| condition.values.all? { |val| val.values.all?(&:present?) } }
              }
            }
          }
        },
        aggs: {
          total_budget: { sum: { field: 'amount' } },
          total_budget_per_inhabitant: { sum: { field: 'amount_per_inhabitant' } },
        },
        size: 0
      }

      type ||= (kind == 'G') ? 'functional' : 'economic'

      result = GobiertoBudgets::SearchEngine.client.search index: index, type: type, body: query
      return result['aggregations']['total_budget']['value'].round(2), result['aggregations']['total_budget_per_inhabitant']['value'].round(2)
    end

    def import_total_budget(year, index, kind, opts = {})
      places_key = opts.fetch(:place_type, :ine)
      places = PlaceDecorator.collection(places_key)

      places.each do |place|
        place.attributes.each do |key, value|
          next if ENV[key].present? && value != ENV[key].to_i
        end

        next if ENV["custom_place_id"].present? && place.custom_place_id != ENV["custom_place_id"]

        total_budget, total_budget_per_inhabitant = get_data(index, place, year, kind)
        if total_budget == 0.0 && kind == 'G'
          total_budget, total_budget_per_inhabitant = get_data(index, place, year, kind, 'economic')
        end

        data = {
          ine_code: place.attributes["place_id"],
          province_id: place.attributes["province_id"],
          autonomy_id: place.attributes["autonomous_region_id"],
          organization_id: place.id.to_s,
          year: year,
          kind: kind,
          total_budget: total_budget,
          total_budget_per_inhabitant: total_budget_per_inhabitant
        }

        id = [place.id,year,kind].join("/")
        GobiertoBudgets::SearchEngine.client.index index: index, type: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type, id: id, body: data
      end
    end

    desc 'Reset ElasticSearch'
    task :reset => :environment do
      TOTAL_BUDGET_INDEXES.each do |index|
        if GobiertoBudgets::SearchEngine.client.indices.exists? index: index
          puts "- Deleting #{index} index"
          GobiertoBudgets::SearchEngine.client.indices.delete index: index
        end
      end
    end

    desc 'Create mappings'
    task :create => :environment do
      TOTAL_BUDGET_INDEXES.each do |index|
        unless GobiertoBudgets::SearchEngine.client.indices.exists? index: index
          puts "- Creating index #{index}"
          GobiertoBudgets::SearchEngine.client.indices.create index: index, body: {
            settings: {
              # Allow 100_000 results per query
              index: { max_result_window: 100_000 }
            }
          }
        end

        create_total_budget_mapping(index, GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type)
      end
    end

    desc "Import total budgets. Example rake total_budget:import['budgets-execution',2014] place_id=28079 province_id=3 autonomous_region_id=5"
    task :import, [:index, :year, :place_type] => :environment do |t, args|
      index = args[:index] if TOTAL_BUDGET_INDEXES.include?(args[:index])
      raise "Invalid index #{args[:index]}" if index.blank?

      if m = args[:year].match(/\A\d{4}\z/)
        year = m[0].to_i
      end

      opts = args.to_h.slice(:place_type)

      import_total_budget(year, index, 'G', **opts)
      import_total_budget(year, index, 'I', **opts)
    end
  end
end
