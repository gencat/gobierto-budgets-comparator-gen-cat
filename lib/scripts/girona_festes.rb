CODE = 338

CSV.open("girona_festes.csv", "wb") do |csv|
  csv << %W{ codigo_ine_municipio nombre_municipio
             poblacion_2010 poblacion_2011 poblacion_2012 poblacion_2013 poblacion_2014 poblacion_2015 poblacion_2016
             gasto_2010 gasto_2011 gasto_2012 gasto_2013 gasto_2014 gasto_2015 gasto_2016 gasto_2017}

  def population(id, year)
    response = GobiertoBudgets::SearchEngine.client.get index: 'data', type: 'population', id: "#{id}/#{year}"
    response['_source']['value']
  rescue
    nil
  end


  places = INE::Places::Province.find_by_slug('girona').places
  pbar = ProgressBar.new("municipios", places.length)

  places.each do |place|
    pbar.inc

    planned = []
    total_planned = []
    executed = []
    total_executed = []
    population = []

    (2010..2016).each do |year|
      population.push(population(place.id, year))
      id = [place.id,year,CODE,'G'].join("/")
      begin
        response = GobiertoBudgets::SearchEngine.client.get(index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, type: 'functional', id: id)
        value = response['_source']['amount']
        planned.push(value)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        planned.push(nil)
      end
    end

    year = 2017
    id = [place.id,year,CODE,'G'].join("/")
    begin
      response = GobiertoBudgets::SearchEngine.client.get(index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, type: 'functional', id: id)
      value = response['_source']['amount']
      planned.push(value)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      planned.push(nil)
    end

    csv << ([place.id, place.name] + population + planned)
  end
  pbar.finish
end

