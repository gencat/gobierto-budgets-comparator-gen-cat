CSV.open("presu-ejecutado-municipios-totales.csv", "wb") do |csv|
  csv << %W{ year amount_gastos amount_ingresos }

  pbar = ProgressBar.new("municipios", 6*INE::Places::Place.all.length)

  (2010..2015).each do |year|
    total_g = 0
    total_i = 0

    INE::Places::Place.all.each do |place|
      pbar.inc
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
        total_g += g_forecast - g_executed
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
        total_i += i_forecast - i_executed
      end
    end

    csv << [year, total_g.round(2), total_i.round(2)]
  end

  pbar.finish
end

