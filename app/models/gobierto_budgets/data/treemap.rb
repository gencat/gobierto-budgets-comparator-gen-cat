module GobiertoBudgets
  module Data
    class Treemap
      def initialize(options)
        @place = options[:place]
        @kind = options[:kind]
        @type = options[:type]
        @year = options[:year]
        @parent_code = options[:parent_code]
        @level = options[:level] || 1
      end

      def generate_json
        options = [
          {term: { organization_id: @place.id }},
          {term: { kind: @kind }},
          {term: { year: @year }},
          {term: { type: @type }}
        ]

        must_not_terms = []
        must_not_terms.push({exists: { field: 'functional_code'}})
        must_not_terms.push({exists: { field: 'custom_code'}})

        if @parent_code.nil?
          options.push({term: { level: @level }})
        else
          options.push({term: { parent_code: @parent_code }})
        end

        query = {
          sort: [
            { amount: { order: 'desc' } }
          ],
          query: {
            bool: {
              must: options
            }.merge(must_not_terms.present? ? { must_not: must_not_terms } : {})
          },
          size: 10_000
        }

        areas = @type == 'economic' ? EconomicArea : FunctionalArea

        response = SearchEngine.client.search index: SearchEngineConfiguration::BudgetLine.index_forecast, body: query
        children_json = response['hits']['hits'].map do |h|
          {
            name: areas.all_items[@kind][h['_source']['code']],
            code: h['_source']['code'],
            budget: h['_source']['amount'],
            budget_per_inhabitant: h['_source']['amount_per_inhabitant'],
            population: @place.population?
          }
        end

        return {
          name: @type,
          children: children_json
        }.to_json
      end
    end
  end
end
