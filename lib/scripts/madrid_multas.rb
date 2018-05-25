CODE = 391

CSV.open("multas.csv", "wb") do |csv|
  csv << %W{ codigo_ine_municipio nombre_municipio
             poblacion_2010 poblacion_2011 poblacion_2012 poblacion_2013 poblacion_2014 poblacion_2015 poblacion_2016
             ingresos_2010 ingresos_2011 ingresos_2012 ingresos_2013 ingresos_2014 ingresos_2015 ingresos_2016 }

  def population(id, year)
    response = GobiertoBudgets::SearchEngine.client.get index: 'data', type: 'population', id: "#{id}/#{year}"
    response['_source']['value']
  rescue
    nil
  end


  places = INE::Places::Place.all
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
      id = [place.id,year,CODE,'I'].join("/")
      begin
        response = GobiertoBudgets::SearchEngine.client.get(index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_executed, type: 'economic', id: id)
        value = response['_source']['amount']
        planned.push(value)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        planned.push(nil)
      end
    end

    csv << ([place.id, place.name] + population + planned)
  end

  pbar.finish
end
