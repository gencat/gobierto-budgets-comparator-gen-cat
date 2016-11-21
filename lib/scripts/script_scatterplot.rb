(2011..2015).each do |year|
  puts year
  provinces = INE::Places::Province.all.map{|p| {id: p.id, name: p.name, aarr_id: p.autonomous_region.id, aarr_name: p.autonomous_region.name}}
  filters = { per_inhabitant: { from:1 , to: GobiertoBudgets::BudgetTotal::PER_INHABITANT_FILTER_MAX} }
  budgeted = GobiertoBudgets::BudgetTotal.budget_total_query(year: year, variable: 'total_budget_per_inhabitant', filters: filters)['hits']['hits'].map {|h| h['_source'] }
  executed = GobiertoBudgets::BudgetTotal.budget_total_query(year: year, variable: 'total_budget_per_inhabitant', filters: filters, executed: true)['hits']['hits'].map {|h| h['_source'] }
  population = GobiertoBudgets::Population.population_query_results(year: year)

  results = []
  budgeted.each do |b|
    e = executed.find{|et| et['ine_code'] == b['ine_code'] }
    p = population.find{|po| po['ine_code'] == b['ine_code'] }
    next unless (e && p)
    place = INE::Places::Place.find(b['ine_code'])
    results << {
      year: b['year'],
      ine_code: b['ine_code'],
      name: place.name,
      province_id: place.province.id,
      aarr_id: place.province.autonomous_region.id,
      population: p['value'],
      budgeted_total: b['total_budget'],
      budgeted_inhabitant: b['total_budget_per_inhabitant'],
      executed_total: e['total_budget'],
      executed_inhabitant: e['total_budget_per_inhabitant']
    }
  end

  File.open("#{year}.json", 'wb+') do |f|
    f.write(results.to_json)
  end
end
