module GobiertoBudgets
  class Ranking
    class OutOfBounds < StandardError; end

    # This class is used in the ranking table to provide the information for each row
    class Item < OpenStruct
    end

    def self.per_page
      100
    end

    def self.position(i, page)
      (page - 1)*self.per_page + i + 1
    end

    def self.page_from_position(position)
      return 1 if position.nil? || position < 1
      (position.to_f / self.per_page.to_f).ceil
    end

    def self.query(options)
      year = options[:year]
      variable = options[:variable]
      kind = options[:kind]
      page = options[:page]
      code = options[:code]
      places_collection = options[:places_collection]
      filters = options[:filters]

      offset = (page-1)*self.per_page

      results, total_results = if code
        self.budget_line_ranking(options, offset)
      elsif variable == 'population'
        self.population_ranking(variable, year, offset, places_collection, filters)
      else
        self.total_budget_ranking(variable, year, kind, offset, places_collection, filters)
      end

      Kaminari.paginate_array(results, limit: self.per_page, offset: offset, total_count: total_results)
    end

    ## Private
    def self.budget_line_ranking(options, offset)
      results, total_elements = BudgetLine.for_ranking(options.merge(offset: offset, per_page: self.per_page), true)

      places_collection = options[:places_collection]
      places_ids = results.map{|h| h['ine_code']}
      total_results = BudgetTotal.for_places(places_ids, options[:year])
      total_results = Hash[total_results.map{ |i| [i["ine_code"], i["total_budget"]]}]

      return results.map do |h|
        id = h['ine_code'].to_i

        Item.new({
          place: INE::Places::Place.find(id),
          population: h['population'],
          amount_per_inhabitant: h['amount_per_inhabitant'],
          amount: h['amount'],
          total: total_results[id]
        })
      end, total_elements
    end

    def self.population_ranking(variable, year, offset, places_collection, filters)
      results, total_elements = Population.for_ranking(year, offset, self.per_page, places_collection, filters)

      places_ids = results.map{|h| h['ine_code']}
      total_results = BudgetTotal.for_places(places_ids, year)
      total_results = Hash[total_results.map{ |i| [i["ine_code"], {total_budget: i["total_budget"], total_budget_per_inhabitant: i["total_budget_per_inhabitant"]}]}]

      return results.map do |h|
        id = h['ine_code'].to_i

        Item.new({
          place: INE::Places::Place.find(id),
          population: h["value"],
          amount_per_inhabitant: total_results[id][:total_budget_per_inhabitant],
          amount: total_results[id][:total_budget],
          total: total_results[id][:total_budget]
        })
      end, total_elements
    end

    def self.total_budget_ranking(variable, year, kind, offset, places_collection, filters)
      variable = if variable == 'amount'
                   'total_budget'
                 elsif variable == 'population'
                   variable
                 else
                   'total_budget_per_inhabitant'
                 end

      results, total_elements = BudgetTotal.for_ranking(year, variable, kind, offset, self.per_page, places_collection, filters)
      if (results.nil? || results.empty?) && total_elements > 0
        raise OutOfBounds
      end

      places_ids = results.map {|h| h['ine_code']}
      population_results = Population.for_places(places_ids, year)
      population_results = Hash[population_results.map{ |i| [i["ine_code"], i["value"]] }]

      return results.map do |h|
        id = h['ine_code'].to_i

        Item.new({
          place: INE::Places::Place.find(id),
          population: population_results[id],
          amount_per_inhabitant: h['total_budget_per_inhabitant'],
          amount: h['total_budget'],
          total: h['total_budget']
        })
      end, total_elements
    end
  end
end
