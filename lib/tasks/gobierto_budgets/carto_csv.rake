namespace :gobierto_budgets do
  namespace :carto do
    desc 'Export main indicators'
    task export_main_indicators: :environment do
      CSV.open("indicators.csv", "wb") do |csv|
        csv << ['year', 'place_id', 'gasto_por_habitante', 'gasto_total', 'planned_vs_executed','population','debt']
        GobiertoBudgets::SearchEngineConfiguration::Year.all.each do |year|
          puts year
          INE::Places::Place.all.each do |place|
            csv << [year, place.id, get_expense_per_inhabitant(place, year), get_total_expense(place, year),
                    get_planned_vs_executed(place, year), get_population(place, year), get_debt(place, year)]
          end
        end
      end
    end

    desc 'Export planned budgets CSVs'
    task export_planned_budgets: :environment do
      CSV.open("planned_budgets.csv", "wb") do |csv|
        csv << ['year', 'place_id', 'area', 'kind', 'amount', 'code', 'amount_per_inhabitant']
        GobiertoBudgets::SearchEngineConfiguration::Year.all.each do |year|
          puts year
          INE::Places::Place.all.each do |place|
            get_budgets(place, year, 'economic').each do |budget_line|
              csv << [year, budget_line['ine_code'], 'e', budget_line['kind'], budget_line['amount'], budget_line['code'], budget_line['amount_per_inhabitant']]
            end
            get_budgets(place, year, 'functional').each do |budget_line|
              csv << [year, budget_line['ine_code'], 'f', budget_line['kind'], budget_line['amount'], budget_line['code'], budget_line['amount_per_inhabitant']]
            end
          end
        end
      end
    end

    def get_budgets(place, year, area)
      terms = [
        {term: { year: year }},
        {missing: { field: 'functional_code'}},
        {term: { ine_code: place.id }}
      ]

      query = {
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

      response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, type: area, body: query
      response['hits']['hits'].map{|h| h['_source'] }
    end

    def get_expense_per_inhabitant(place, year)
      kind = 'G'
      id = [place.id,year,kind].join("/")
      result = GobiertoBudgets::SearchEngine.client.get index: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_forecast, type: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type, id: id
      value = result['_source']['total_budget_per_inhabitant'].to_f
      raise Elasticsearch::Transport::Transport::Errors::NotFound if value == 0.0
      return value
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      year = year - 1
      if year >= GobiertoBudgets::SearchEngineConfiguration::Year.first
        retry
      end
    end

    def get_total_expense(place, year)
      kind = 'G'
      id = [place.id,year,kind].join("/")
      result = GobiertoBudgets::SearchEngine.client.get index: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_forecast, type: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type, id: id
      value = result['_source']['total_budget'].to_f
      raise Elasticsearch::Transport::Transport::Errors::NotFound if value == 0.0
      value
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      year = year - 1
      if year >= GobiertoBudgets::SearchEngineConfiguration::Year.first
        retry
      end
    end

    def get_total_expense_executed(place, year)
      kind = 'G'
      id = [place.id,year,kind].join("/")
      result = GobiertoBudgets::SearchEngine.client.get index: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_executed, type: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type, id: id
      value = result['_source']['total_budget'].to_f
      raise Elasticsearch::Transport::Transport::Errors::NotFound if value == 0.0
      value
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      year = year - 1
      if year >= GobiertoBudgets::SearchEngineConfiguration::Year.first
        retry
      end
    end

    def get_planned_vs_executed(place, year)
      planned = get_total_expense(place, year)
      executed = get_total_expense_executed(place, year)
      if planned and executed and executed != 0
        delta_percentage(executed,planned).to_f.round(2)
      else
        nil
      end
    end

    def get_population(place, year)
      id = [place.id,year].join("/")
      result = GobiertoBudgets::SearchEngine.client.get index: GobiertoBudgets::SearchEngineConfiguration::Data.index, type: GobiertoBudgets::SearchEngineConfiguration::Data.type_population, id: id
      result['_source']['value'].to_i
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      begin
        id = [place.id,year-1].join("/")
        result = GobiertoBudgets::SearchEngine.client.get index: GobiertoBudgets::SearchEngineConfiguration::Data.index, type: GobiertoBudgets::SearchEngineConfiguration::Data.type_population, id: id
        result['_source']['value'].to_i
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
      end
    end

    def get_debt(place, year)
      id = [place.id,year].join("/")
      result = GobiertoBudgets::SearchEngine.client.get index: GobiertoBudgets::SearchEngineConfiguration::Data.index, type: GobiertoBudgets::SearchEngineConfiguration::Data.type_debt, id: id
      result['_source']['value'].to_f
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      begin
        id = [place.id,year-1].join("/")
        result = GobiertoBudgets::SearchEngine.client.get index: GobiertoBudgets::SearchEngineConfiguration::Data.index, type: GobiertoBudgets::SearchEngineConfiguration::Data.type_debt, id: id
        result['_source']['value'].to_f
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
      end
    end

    def delta_percentage(value, old_value)
      return "" if value.nil? || old_value.nil?
      ((value.to_f - old_value.to_f)/old_value.to_f) * 100
    end
  end
end
