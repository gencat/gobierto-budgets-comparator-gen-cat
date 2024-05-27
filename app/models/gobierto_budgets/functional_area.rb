module GobiertoBudgets
  class FunctionalArea
    include Describable

    EXPENSE = 'G'

    def self.all_items
      @all_items ||= {}
      @all_items[I18n.locale] ||= begin
        all_items = {
          EXPENSE => {}
        }

        query = {
          query: {
            bool: {
              must: [
                {term: { area: 'functional' }},
                {term: { type: SearchEngineConfiguration::BudgetCategories.type }}
              ]
            }
          },
          size: 10_000
        }
        response = SearchEngine.client.search index: SearchEngineConfiguration::BudgetCategories.index, body: query

        response['hits']['hits'].each do |h|
          source = h['_source']
          source['kind'] = source['kind'] == 'income' ? 'I' : 'G'
          all_items[source['kind']][source['code']] = source['name']
        end

        all_items
      end
    end
  end
end
