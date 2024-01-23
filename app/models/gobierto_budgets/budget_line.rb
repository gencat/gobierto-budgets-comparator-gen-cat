module GobiertoBudgets
  class BudgetLine < OpenStruct

    include CommonQueryBehavior

    INCOME = 'I'
    EXPENSE = 'G'
    ECONOMIC = 'economic'
    FUNCTIONAL = 'functional'
    AREA_NAMES = [ECONOMIC, FUNCTIONAL].freeze

    @sort_attribute ||= 'code'
    @sort_order ||= 'asc'

    def self.where(conditions)
      @conditions = conditions
      self
    end

    def self.search(options)

      terms = [
        { term: { kind: options[:kind] } },
        { missing: { field: 'functional_code' } },
        { missing: { field: 'custom_code' } },
        { term: { year: options[:year] } }
      ]

      terms << {term: { organization_id: options[:organization_id] }} if options[:organization_id].present?
      terms << {term: { ine_code: options[:ine_code] }} if options[:ine_code].present?
      terms << {term: { parent_code: options[:parent_code] }} if options[:parent_code].present?
      terms << {term: { level: options[:level] }} if options[:level].present?
      terms << {term: { code: options[:code] }} if options[:code].present?

      if options[:range_hash].present?
        options[:range_hash].each_key do |range_key|
          terms << {range: { range_key => options[:range_hash][range_key] }}
        end
      end

      query = {
        sort: [
          { code: { order: 'asc' } }
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
        aggs: {
          total_budget: { sum: { field: 'amount' } },
          total_budget_per_inhabitant: { sum: { field: 'amount_per_inhabitant' } },
        },
        size: 10_000
      }

      response = GobiertoBudgets::SearchEngine.client.search(
        index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast,
        type: (options[:type] || 'economic'),
        body: query
      )

      # HACK: aggregation values returned by ES are wrong. This option recalculates them.
      if options[:recalculate_aggregations] == true
        total_budget = response["hits"]["hits"].map { |h| h["_source"]["amount"] }.sum
        total_budget_per_inhabitant = response["hits"]["hits"].map { |h| h["_source"]["amount_per_inhabitant"] }.compact.sum
        response["aggregations"]["total_budget"]["value"] = total_budget
        response["aggregations"]["total_budget_per_inhabitant"]["value"] = total_budget_per_inhabitant
      end

      return {
        'hits' => response['hits']['hits'].map{ |h| h['_source'] },
        'aggregations' => response['aggregations']
      }
    end

    def self.budget_line_query(options, only_municipalities=false)
      terms = [
        { term: { year: options[:year] } },
        { term: { kind: options[:kind] } },
        { term: { code: options[:code] } }
      ]

      places_restriction = GobiertoBudgets::PlaceSet.new(places_collection: options[:places_collection])

      permitted_organizations = []

      if options[:filters].present?
        population_filter = options[:filters][:population]
        total_filter = options[:filters][:total]
        per_inhabitant_filter = options[:filters][:per_inhabitant]
        aarr_filter = options[:filters][:aarr] if options[:filters][:aarr] != 'undefined'
      end

      if (population_filter && (population_filter[:from].to_i > GobiertoBudgets::Population::FILTER_MIN || population_filter[:to].to_i < GobiertoBudgets::Population::FILTER_MAX))
        reduced_filter = { population: population_filter }
        reduced_filter.merge!(aarr: aarr_filter) if aarr_filter
        results, total_elements = GobiertoBudgets::Population.for_ranking(options[:year], 0, nil, reduced_filter)
        places_restriction.restrict(
          ine_codes: results.map { |r| r["ine_code"] }.compact_blank,
          organization_ids: results.map { |r| r["organization_id"] }.compact_blank
        )
      end

      append_ine_codes(terms, places_restriction.ine_codes)
      append_organization_ids(terms, places_restriction.organization_ids + places_restriction.associated_entity_ids)

      if total_filter && (
        total_filter[:from].to_i > GobiertoBudgets::BudgetTotal::TOTAL_FILTER_MIN ||
        total_filter[:to].to_i < GobiertoBudgets::BudgetTotal::TOTAL_FILTER_MAX
      )
        terms << {
          range: {
            amount: { gte: total_filter[:from].to_i, lte: total_filter[:to].to_i }
          }
        }
      end

      if per_inhabitant_filter && (
        per_inhabitant_filter[:from].to_i > GobiertoBudgets::BudgetTotal::PER_INHABITANT_FILTER_MIN ||
        per_inhabitant_filter[:to].to_i < GobiertoBudgets::BudgetTotal::PER_INHABITANT_FILTER_MAX
      )
        terms << {
          range: {
            amount_per_inhabitant: { gte: per_inhabitant_filter[:from].to_i, lte: per_inhabitant_filter[:to].to_i }
          }
        }
      end

      terms << {term: { autonomy_id: aarr_filter }}  unless aarr_filter.blank?
      terms << { exists: { field: "ine_code" } } if only_municipalities
      terms << { missing: { field: "custom_code" } }
      terms << { missing: { field: "functional_code" } }

      query = {
        sort: [ { options[:variable].to_sym => { order: 'desc' } } ],
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

      GobiertoBudgets::SearchEngine.client.search(
        index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast,
        type: options[:area_name],
        body: query,
        filter_path: options[:to_rank] ? "hits.total" : "hits.hits._source,hits.total",
        _source: ["population", "ine_code", "organization_id", "amount", "amount_per_inhabitant"]
      )
    end

    def self.find(options)
      return self.search(options)['hits'].detect{|h| h['code'] == options[:code] }
    end

    def self.for_ranking(options, only_municipalities=false)
      response = budget_line_query(options, only_municipalities)
      if results = response['hits']['hits']
        return results.map{|h| h['_source']}, response['hits']['total']
      else
        return [], 0
      end
    end

    def self.place_position_in_ranking(options, only_municipalities=false)
      id = %w{organization_id year code kind}.map {|f| options[f.to_sym]}.join('/')
      response = budget_line_query(options.merge(to_rank: true), only_municipalities)
      position = response['hits']['hits'].map{ |h| h['_id'] }.index(id) + 1 rescue 0
      return position, response['hits']['total']
    end

    def self.compare(options)
      terms = [{terms: { ine_code: options[:ine_codes] }},
               {term: { level: options[:level] }},
               {term: { kind: options[:kind] }},
               {term: { year: options[:year] }}]

      terms << {term: { parent_code: options[:parent_code] }} if options[:parent_code].present?
      terms << {term: { code: options[:code] }} if options[:code].present?

      query = {
        sort: [
          { code: { order: 'asc' } },
          { ine_code: { order: 'asc' }}
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

      response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, type: options[:type] , body: query
      response['hits']['hits'].map{ |h| h['_source'] }
    end

    def self.compare_with_ancestors(options)
      terms = [{terms: { ine_code: options[:ine_codes] }},
                {term: { kind: options[:kind] }},
                {term: { year: options[:year] }},
                {range: { level: { lte: options[:level].to_i } }},
                {bool: {
                  should: [
                    {wildcard: { code: "#{options[:parent_code][0]}*" }},
                    {term: { parent_code: '' }}
                    ]
                  }
                }]

      query = {
        sort: [
          { code: { order: 'asc' } },
          { ine_code: { order: 'asc' }}
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

      response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, type: options[:type] , body: query
      response['hits']['hits'].map{ |h| h['_source'] }
    end

    def self.has_children?(options)
      options.symbolize_keys!
      conditions = { parent_code: options[:code], level: options[:level].to_i + 1, type: options[:area] }
      conditions.merge! options.slice(:ine_code, :kind, :year, :organization_id).compact_blank

      return search(conditions)['hits'].length > 0
    end

    def self.top_differences(options)
      terms = [{term: { kind: options[:kind] }}, {term: { year: options[:year] }}, {term: { level: 3 }}]
      terms << {term: { organization_id: options[:organization_id] }} if options[:organization_id].present?
      terms << {term: { ine_code: options[:ine_code] }} if options[:ine_code].present?
      terms << {term: { code: options[:code] }} if options[:code].present?

      query = {
        sort: [
          { code: { order: 'asc' } }
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

      response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, type: (options[:type] || 'economic'), body: query

      planned_results = response['hits']['hits'].map{ |h| h['_source'] }

      response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_executed, type: (options[:type] || 'economic'), body: query

      executed_results = response['hits']['hits'].map{ |h| h['_source'] }

      results = {}
      planned_results.each do |p|
        if p["amount"].to_f.positive? && (e = executed_results.detect{|e| e['code'] == p['code']})
          results[p['code']] = [p['amount'], e['amount'], ((e['amount'].to_f - p['amount'].to_f)/p['amount'].to_f) * 100]
        end
      end

      return results.sort{ |b, a| a[1][2] <=> b[1][2] }[0..15], results.sort{ |a, b| a[1][2] <=> b[1][2] }[0..15]
    end

    def self.top_values(options)
      terms = [{term: { kind: GobiertoBudgets::BudgetLine::INCOME }}, {term: { year: options[:year] }}, {term: { level: 3 }}]
      terms << {term: { ine_code: options[:ine_code] }}

      query = {
        sort: [
          { amount: { order: 'desc' } }
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
        size: 5
      }

      response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, type: 'economic', body: query

      income_entries = response['hits']['hits'].map{ |h| h['_source'] }

      terms = [{term: { kind: GobiertoBudgets::BudgetLine::EXPENSE }}, {term: { year: options[:year] }}, {term: { level: 3 }}]
      terms << {term: { ine_code: options[:ine_code] }}

      query = {
        sort: [
          { amount: { order: 'desc' } }
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
        size: 5
      }

      response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, type: 'functional', body: query

      expense_entries = response['hits']['hits'].map{ |h| h['_source'] }

      return income_entries, expense_entries
    end

    def to_param
      {place_id: place_id, year: year, code: code, area_name: area_name, kind: kind}
    end

    def place
      if place_id
        PlaceDecorator.find_in_all_collections(place_id)
      end
    end

    def category
      area = area_name == 'economic' ? EconomicArea : FunctionalArea
      area.all_items[self.kind][self.code]
    end
  end
end
