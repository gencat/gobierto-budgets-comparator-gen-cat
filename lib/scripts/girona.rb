def area_class(area, kind)
  return GobiertoBudgets::FunctionalArea if (area == 'functional' && %{income i}.exclude?(kind.downcase))
  GobiertoBudgets::EconomicArea
end

def budget_line_denomination(area, code, kind, capped = -1)
  area = area_class area, kind
  if area.all_items[kind][code].nil?
    res = " - "
  else
    res = area.all_items[kind][code][0..capped]
  end
  res
end

CSV.open("girona.csv", "wb") do |csv|
  csv << %W{ place_id place_name type pre_eje kind code nombre year amount amount_per_inhabitant }

  province = INE::Places::Province.find_by_slug 'girona'
  province.places.each do |place|
    (2010..2015).each do |year|
      ['economic', 'functional'].each do |type|
        query = {
          :query => {
            :filtered => {
              :filter => {
                :bool => {
                  :must => [
                    {:term=>{:ine_code => place.id}},
                    {:term=>{:year => year}},
                    {:missing => { field: 'functional_code'}}
                  ]
                }
              }
            }
          },
          :size=>100_000
        }

        response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, type: type, body: query

        response['hits']['hits'].each do |line|
          budget_line =  line['_source']
          csv << [place.id, place.name, type, 'presupuestado', budget_line['kind'], budget_line['code'], budget_line_denomination(type,budget_line['code'],budget_line['kind']), year, budget_line['amount'], budget_line['amount_per_inhabitant']]
        end

        response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_executed, type: type, body: query

        response['hits']['hits'].each do |line|
          budget_line =  line['_source']
          csv << [place.id, place.name, type, 'ejecutado', budget_line['kind'], budget_line['code'], budget_line_denomination(type,budget_line['code'],budget_line['kind']), year, budget_line['amount'], budget_line['amount_per_inhabitant']]
        end
      end
    end
  end
end
