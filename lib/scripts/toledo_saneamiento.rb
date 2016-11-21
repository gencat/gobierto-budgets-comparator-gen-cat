CODE = 161

CSV.open("toledo-saneamiento.csv", "wb") do |csv|
  csv << %W{ codigo_ine_municipio nombre_municipio
             poblacion_2010 poblacion_2011 poblacion_2012 poblacion_2013 poblacion_2014 poblacion_2015
             presupuestado_2010 presupuestado_2011 presupuestado_2012 presupuestado_2013 presupuestado_2014 presupuestado_2015
             t_presupuestado_2010 t_presupuestado_2011 t_presupuestado_2012 t_presupuestado_2013 t_presupuestado_2014 t_presupuestado_2015
             ejecutado_2010 ejecutado_2011 ejecutado_2012 ejecutado_2013 ejecutado_2013 ejecutado_2015
             t_ejecutado_2010 t_ejecutado_2011 t_ejecutado_2012 t_ejecutado_2013 t_ejecutado_2013 t_ejecutado_2015 }

  def population(id, year)
    response = GobiertoBudgets::SearchEngine.client.get index: 'data', type: 'population', id: "#{id}/#{year}"
    response['_source']['value']
  rescue
    nil
  end


  province = INE::Places::Province.find_by_slug('toledo')
  pbar = ProgressBar.new("municipios", province.places.length)

  province.places.each do |place|
    pbar.inc

    planned = []
    total_planned = []
    executed = []
    total_executed = []
    population = []

    (2010..2015).each do |year|

      population.push(population(place.id, year))

      id = [place.id,year,CODE,'G'].join("/")
      begin
        response = GobiertoBudgets::SearchEngine.client.get(index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, type: 'functional', id: id)
        value = response['_source']['amount']
        planned.push(value)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        planned.push(nil)
      end

      id = [place.id, year, 'G'].join('/')
      begin
        response = GobiertoBudgets::SearchEngine.client.get(index: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_forecast, type: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type, id: id)
        value = response['_source']['total_budget']
        total_planned.push(value)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        total_planned.push(nil)
      end

      begin
        response = GobiertoBudgets::SearchEngine.client.get(index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_executed, type: 'functional', id: id)
        value = response['_source']['amount']
        executed.push(value)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        executed.push(nil)
      end

      id = [place.id, year, 'G'].join('/')
      begin
        response = GobiertoBudgets::SearchEngine.client.get(index: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_executed, type: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type, id: id)
        value = response['_source']['total_budget']
        total_executed.push(value)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        total_executed.push(nil)
      end
    end

    csv << ([place.id, place.name] + population + planned + total_planned + executed + total_executed)
  end
  pbar.finish
end

