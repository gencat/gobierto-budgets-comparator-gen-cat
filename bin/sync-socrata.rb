# [place.id,year,code,kind].join("/")

def population(id, year)
  response = GobiertoBudgets::SearchEngine.client.get index: 'data', type: 'population', id: "#{id}/#{year}"
  response['_source']['value']
rescue
  nil
end

index = GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast

CSV.foreach("execucions.csv", headers: true) do |row|
  next unless row['NOM_COMPLERT'].downcase.starts_with?('ajun')
  year = row[0].match(/\A\d\d\/\d\d\/(\d{4})\s/)[1].to_i
  entity = row['CODI_ENS']
  place = INE::Places::Place.find entity[0..-6]
  debugger
  next if place.nil?
  next if row["IMPORT"].nil?

  kind = row[1] == 'I' ? 'I' : 'G'
  area = row[2] == 'E' ? 'economic' : 'functional'
  area_klass = area == 'economic' ? GobiertoBudgets::EconomicArea : GobiertoBudgets::FunctionalArea
  code = row[3]
  level = row[4].to_i
  amount = row[6].to_f
  debugger
  next if amount == 0

  if code.length > 3
    preffix = code[0..2]
    suffix = code[3..-1]
    code = "#{preffix}-#{format('%.2d', suffix.to_i)}"
  end

  if code.length == 3 and level == 4
    code = "#{code}-00"
  end

  if row[5] == 'Deute públic' && code.to_i != 0
    code = "0#{code}"
  end

  if code.length != 6 && code.length != level
    raise row.to_s
  end

  id = [place.id, year, code, kind].join('/')
  begin
    response = GobiertoBudgets::SearchEngine.client.get index: index, type: area, id: id
    stored_amount = response['_source']['amount']
    if stored_amount != amount && amount != 0.0
      pop = population(place.id, year) || population(place.id, year - 1)
      if pop
        doc = response['_source']
        GobiertoBudgets::SearchEngine.client.index index: index, type: area, id: id, body: doc.merge('amount' => amount, 'amount_per_inhabitant' => (amount.to_f / pop).round(2))
        putc 'x'
      end
    end
  rescue Elasticsearch::Transport::Transport::Errors::NotFound
    pop = population(place.id, year) || population(place.id, year - 1)
    parent_code = code[0..-2]
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
    GobiertoBudgets::SearchEngine.client.index index: index, type: area, id: id, body: data
    putc '+'
  end
end
