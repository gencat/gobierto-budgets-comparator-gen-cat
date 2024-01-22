module GobiertoBudgets
  class Population

    include CommonQueryBehavior

    FILTER_MIN = 0
    FILTER_MAX = 5000000

    def self.for(organization_id, year)
      return for_places(organization_id, year) if organization_id.is_a?(Array)
      result = population_query_results(organization_id: organization_id, year: year)
      if result.empty?
        result = population_query_results(organization_id: organization_id, year: year-1)
      end
      result.first['value'].to_f
    end

    def self.for_places(organization_ids, year)
      results = population_query_results(organization_ids: organization_ids, year: year)
      if results.empty?
        results = population_query_results(organization_ids: organization_ids, year: year - 1)
      end
      results
    end

    def self.for_year(year, opts = {})
      results = population_query_results(opts.merge(year: year))
      if results.empty?
        results = population_query_results(opts.merge(year: year - 1))
      end
      results
    end

    def self.for_ranking(year, offset, per_page, filters)
      response = population_query(year: year, offset: offset, per_page: per_page, filters: filters)
      total_elements = response['hits']['total']
      if total_elements == 0
        response = population_query(year: year-1, offset: offset, per_page: per_page, filters: filters)
        total_elements = response['hits']['total']
      end
      if result = response['hits']['hits']
        return result.map{|h| h['_source']}, total_elements
      else
        return [], 0
      end
    end

    def self.ranking_hash_for(organization_id, year, opts = {})

      buckets = for_year year, opts

      place = PlaceDecorator.find(organization_id, **opts.slice(:places_collection))
      population_organization_id = place.population_organization_id
      if row = buckets.detect{|v| v['organization_id'].to_s == population_organization_id.to_s }
        value = row['value']
      end

      position = buckets.index(row) + 1 rescue nil

      return {
        value: value,
        position: position,
        total_elements: buckets.length
      }
    end

    def self.place_position_in_ranking(year, ine_code, filters)
      id = [ine_code, year].join('/')
      response = population_query({year: year, to_rank: true, filters: filters})
      total_elements = response['hits']['total']
      if total_elements == 0
        response = population_query({year: year-1, to_rank: true, filters: filters})
        total_elements = response['hits']['total']
      end
      buckets = response['hits']['hits'].map{|h| h['_id']}
      position = buckets.index(id) ? buckets.index(id) + 1 : 0;
      return position + 1
    end

    private

    def self.population_query(options)
      terms = []
      ine_codes = options[:ine_codes] || []
      organization_ids = options[:organization_ids] || []

      type = PlaceDecorator.population_type_index(options[:places_collection])

      if GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope?
        ine_codes.concat(GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope)
        organization_ids.concat(GobiertoBudgets::SearchEngineConfiguration::Scopes.organization_ids)
      end

      append_ine_codes(terms, ine_codes)
      append_organization_ids(terms, organization_ids)
      terms << {term: { ine_code: options[:ine_code] }} if options[:ine_code].present?
      terms << {term: { organization_id: options[:organization_id] }} if options[:organization_id].present?
      terms << {term: { year: options[:year] }}

      if options[:filters].present?
        population_filter =  options[:filters][:population]
        total_filter = options[:filters][:total]
        per_inhabitant_filter = options[:filters][:per_inhabitant]
        aarr_filter = options[:filters][:aarr] if options[:filters][:aarr] != 'undefined'
      end

      if total_filter || per_inhabitant_filter
        budget_filters = {}

        if (total_filter && (total_filter[:from].to_i > BudgetTotal::TOTAL_FILTER_MIN || total_filter[:to].to_i < BudgetTotal::TOTAL_FILTER_MAX))
          budget_filters[:total] = total_filter
        end

        if (per_inhabitant_filter && (per_inhabitant_filter[:from].to_i > BudgetTotal::PER_INHABITANT_FILTER_MIN || per_inhabitant_filter[:to].to_i < BudgetTotal::PER_INHABITANT_FILTER_MAX))
          budget_filters[:per_inhabitant] = per_inhabitant_filter
        end

        budget_filters.merge!(aarr: aarr_filter) if aarr_filter

        results, total_elements = BudgetTotal.for_ranking(options[:year], 'total_budget', GobiertoBudgets::BudgetLine::EXPENSE, 0, nil, budget_filters)
        ine_codes = results.map{ |p| p["ine_code"] }.compact_blank
        organization_ids = results.map{ |p| p["organization_id"] }.compact_blank
        append_ine_codes(terms, ine_codes)
        append_organization_ids(terms, organization_ids)
      end

      if (population_filter && (population_filter[:from].to_i > Population::FILTER_MIN || population_filter[:to].to_i < Population::FILTER_MAX))
        terms << {range: { value: { gte: population_filter[:from].to_i, lte: population_filter[:to].to_i} }}
      end

      terms << { term: { autonomous_region_id: aarr_filter } } unless aarr_filter.blank?

      query = {
        sort: [
          { value: { order: 'desc' } }
        ],
        query: {
          filtered: {
            filter: {
              bool: {
                must: terms
              }
            }
          }
        },
        size: 10_000
      }

      query.merge!(size: options[:per_page]) if options[:per_page].present?
      query.merge!(from: options[:offset]) if options[:offset].present?
      query.merge!(_source: false) if options[:to_rank]

      SearchEngine.client.search(
        index: SearchEngineConfiguration::Data.index,
        type: type,
        body: query,
        filter_path: options[:to_rank] ? "hits.total" : "hits.hits._source,hits.total",
        _source: ["value", "ine_code", "organization_id"]
      )
    end

    def self.population_query_results(options)
      if result = population_query(options)['hits']['hits']
        result.map{|h| h['_source']}
      else
        []
      end
    end

  end
end
