require 'soda/client'

def population(id, year)
  response = GobiertoBudgets::SearchEngine.client.get index: 'data', type: 'population', id: "#{id}/#{year}"
  response['_source']['value']
rescue
  nil
end

def process_response(response_item)
  return unless response_item.nom_complert.downcase.starts_with?('ajun')
  entity = response_item.codi_ens
  place = INE::Places::Place.find(entity[0..-6])
  return if place.nil?
  return if response_item.import.nil?

  kind = response_item.tipus_partida == 'I' ? 'I' : 'G'
  area = response_item.tipus_classif == 'E' ? 'economic' : 'functional'
  area_klass = area == 'economic' ? GobiertoBudgets::EconomicArea : GobiertoBudgets::FunctionalArea
  code = response_item.codi_pantalla
  level = response_item.nivell.to_i
  amount = response_item.import.to_f
  parent_code = code[0..-2]
  return if amount == 0

  index = GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast

  if code.length > 3
    original_code = code
    preffix = code[0..2]
    if code.include?('.')
      suffix = code[4..-1]
    else
      suffix = code[3..-1]
    end
    code = "#{preffix}-#{format('%.2d', suffix.to_i)}"
    parent_code = preffix
    level=4
  end

  if response_item.descripcio == 'Deute públic' && code.to_i != 0
    code = "0#{code}"
  end

  if code.length != 6 && code.length != level
    raise response_item.to_s
  end

  year = Time.parse(response_item.any_exercici).year
  id = [place.id, year, code, kind].join('/')
  begin
    response = GobiertoBudgets::SearchEngine.client.get index: index, type: area, id: id
    stored_amount = response['_source']['amount'].to_f
    if stored_amount != amount && amount != 0.0
      pop = population(place.id, year) || population(place.id, year - 1)
      if pop
        doc = response['_source']
        puts [id, area, amount].join(' x ')
        GobiertoBudgets::SearchEngine.client.index index: index, type: area, id: id, body: doc.merge('amount' => amount, 'amount_per_inhabitant' => (amount.to_f / pop).round(2))
        # putc 'x'
      end
    end
  rescue Elasticsearch::Transport::Transport::Errors::NotFound
    pop = population(place.id, year) || population(place.id, year - 1)
    base_data = {
      ine_code: place.id.to_i, province_id: place.province.id.to_i,
      autonomy_id: place.province.autonomous_region.id.to_i, year: year,
      population: pop
    }
    data = base_data.merge({
      amount: amount.to_f.round(2), code: code,
      level: level, kind: kind,
      amount_per_inhabitant: (amount.to_f / pop).round(2),
      parent_code: parent_code
    })
    puts [id, area, amount].join(' + ')
    GobiertoBudgets::SearchEngine.client.index index: index, type: area, id: id, body: data
    # putc '+'
  end
end

MAX_TRIES = 10
tries = 0
begin
  client = SODA::Client.new({domain: Rails.application.secrets.socrata_host, app_token: Rails.application.secrets.socrata_app_token})
  per_page = 100
  page = 0
  response = client.get("bhg2-qtnp", {"$limit" => per_page, "$offset" => page*per_page})
  while response.any?
    response.each do |response_item|
      process_response(response_item)
    end
    page+=1
    response = client.get("bhg2-qtnp", {"$limit" => per_page, "$offset" => page*per_page})
  end
rescue
  puts $!
  tries += 1
  if tries < MAX_TRIES
    sleep 60
    retry
  end
  puts
  puts "Existing after #{tries} re-tries....."
  puts
end
