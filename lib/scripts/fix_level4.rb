['budgets-forecast-v2','budgets-execution'].each do |index|
  puts index

  type = 'economic'
  puts type

  (2010..2015).each do |year|
    puts year
    INE::Places::Place.all.each do |place|
      ['G','I'].each do |kind|
        query = {
          query: {
            filtered: {
              query: {
                match_all: {}
              },
              filter: {
                bool: {
                  must: [
                    {term: { ine_code: place.id }},
                    {term: { kind: kind }},
                    {term: { level: 6 }},
                    {term: { year: year }},
                  ]
                }
              }
            }
          },
          size: 10_000
        }

        response = SearchEngine.client.search index: index, type: type, body: query
        source = response['hits']['hits']
        source.each do |s|
          putc '.'
          id = s['_id']
          body = s['_source'].merge({'level' => 4, 'parent_code' => s['_source']['code'].split('.').first})
          SearchEngine.client.index index: index, type: type, id: id, body: body
        end
      end
    end
  end

  type = 'functional'
  puts type
  (2010..2015).each do |year|
    puts year
    INE::Places::Place.all.each do |place|
      ['G'].each do |kind|
        query = {
          query: {
            filtered: {
              query: {
                match_all: {}
              },
              filter: {
                bool: {
                  must: [
                    {term: { ine_code: place.id }},
                    {term: { kind: kind }},
                    {term: { level: 6 }},
                    {term: { year: year }},
                  ]
                }
              }
            }
          },
          size: 10_000
        }

        response = SearchEngine.client.search index: index, type: type, body: query
        source = response['hits']['hits']
        source.each do |s|
          id = s['_id']
          body = s['_source'].merge({'level' => 4, 'parent_code' => s['_source']['code'].split('.').first})
          SearchEngine.client.index index: index, type: type, id: id, body: body
        end
      end
    end
  end
end
