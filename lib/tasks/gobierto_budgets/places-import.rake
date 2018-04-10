namespace :gobierto_budgets do
  namespace :places do
    PLACES_INDEXES = [GobiertoBudgets::SearchEngineConfiguration::Data.index]
    PLACES_TYPES = [GobiertoBudgets::SearchEngineConfiguration::Data.type_places]

    def create_places_mapping(index, type)
      m = GobiertoBudgets::SearchEngine.client.indices.get_mapping index: index, type: type
      return unless m.empty?

      # Document identifier: <ine_code>
      #
      # Example: 28079
      GobiertoBudgets::SearchEngine.client.indices.put_mapping index: index, type: type, body: {
        type.to_sym => {
          properties: {
            ine_code:              { type: 'integer', index: 'not_analyzed' },
            organization_id:       { type: 'string',  index: 'not_analyzed' },
            province_id:           { type: 'integer', index: 'not_analyzed' },
            autonomy_id:           { type: 'integer', index: 'not_analyzed' },
            year:                  { type: 'integer', index: 'not_analyzed' },
            name:                  { type: 'string',  index: 'analyzed' },
            slug:                  { type: 'string',  index: 'analyzed' }
          }
        }
      }
    end

    def import_places
      INE::Places::Place.all.each do |place|
        place_name = if place.name.include?(',')
                       place.name.split(',').map{|i| i.strip}.reverse.join(' ')
                     else
                       place.name
                     end
        data = {
          ine_code: place.id.to_i, province_id: place.province.id.to_i, organization_id: place.id.to_s,
          autonomy_id: place.province.autonomous_region.id.to_i, year: 2015,
          name: place_name, slug: place.slug
        }

        id = place.id

        GobiertoBudgets::SearchEngine.client.index index: PLACES_INDEXES.first, type: PLACES_TYPES.first, id: id, body: data
      end
    end

    desc 'Reset ElasticSearch'
    task :reset => :environment do
      PLACES_INDEXES.each do |index|
        if GobiertoBudgets::SearchEngine.client.indices.exists? index: index
          puts "- Deleting #{index} index"
          GobiertoBudgets::SearchEngine.client.indices.delete index: index
        end
      end
    end

    desc 'Create mappings'
    task :create => :environment do
      PLACES_INDEXES.each do |index|
        unless GobiertoBudgets::SearchEngine.client.indices.exists? index: index
          puts "- Creating index #{index}"
          GobiertoBudgets::SearchEngine.client.indices.create index: index, body: {
            settings: {
              # Allow 100_000 results per query
              index: { max_result_window: 100_000 }
            }
          }
        end

        PLACES_TYPES.each do |type|
          puts "- Creating #{index} > #{type}"
          create_places_mapping(index, type)
        end
      end
    end

    desc "Import places from INEPlaces gem file into ElasticSearch. Example rake places:import"
    task :import => :environment do
      import_places
    end
  end
end
