CSV.open("presu-ejecutado-municipios-percent.csv", "wb") do |csv|
  csv << %W{ codigo_ine_municipio nombre_municipio codigo_ine_provincia codigo_ine_autonomia poblacion_2015
2010_diff_gastos 2011_diff_gastos 2012_diff_gastos 2013_diff_gastos 2014_diff_gastos 2015_diff_gastos
2010_diff_ingresos 2011_diff_ingresos 2012_diff_ingresos 2013_diff_ingresos 2014_diff_ingresos 2015_diff_ingresos
  }

  def population(id, year)
    response = GobiertoBudgets::SearchEngine.client.get index: 'data', type: 'population', id: "#{id}/#{year}"
    response['_source']['value']
  rescue
    nil
  end


  pbar = ProgressBar.new("municipios", INE::Places::Place.all.length)

  INE::Places::Place.all.each do |place|
    pbar.inc
    values_g = []
    values_i = []

    pop = population(place.id, 2015)
    next if pop < 5_000

    (2010..2015).each do |year|

      id = [place.id, year, 'G'].join('/')
      begin
        response = GobiertoBudgets::SearchEngine.client.get(index: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_forecast, type: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type, id: id)
        g_forecast = response['_source']['total_budget']
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        g_forecast = nil
      end

      begin
        response = GobiertoBudgets::SearchEngine.client.get(index: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_executed, type: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type, id: id)
        g_executed = response['_source']['total_budget']
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        g_executed = nil
      end

      if g_forecast && g_executed
        if g_forecast == 0
          values_g.push 0
        else
          values_g.push (((g_executed - g_forecast)/g_forecast)*100.0).round(2)
        end
      else
        values_g.push nil
      end

      id = [place.id, year, 'I'].join('/')
      begin
        response = GobiertoBudgets::SearchEngine.client.get(index: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_forecast, type: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type, id: id)
        i_forecast = response['_source']['total_budget']
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        i_forecast = nil
      end

      begin
        response = GobiertoBudgets::SearchEngine.client.get(index: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_executed, type: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type, id: id)
        i_executed = response['_source']['total_budget']
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        i_executed = nil
      end

      if i_forecast && i_executed
        if i_forecast == 0
          values_i.push 0
        else
          values_i.push (((i_executed - i_forecast)/i_forecast)*100.0).round(2)
        end
      else
        values_i.push nil
      end
    end

    csv << ([place.id, place.name, place.province.id, place.province.autonomous_region.id, pop] + values_g + values_i)
  end
  pbar.finish
end

