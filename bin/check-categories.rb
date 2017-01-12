missing = {
  'economic' => {},
  'functional' => {}
}

CSV.foreach("pressupostos.csv", headers: true) do |row|
  next unless row['NOM_COMPLERT'].downcase.starts_with?('ajun')
  entity = row['CODI_ENS']
  place = INE::Places::Place.find entity[0..-6]
  next if place.nil?
  next if row["IMPORT"].nil?

  kind = row[1] == 'I' ? 'I' : 'G'
  area = row[2] == 'E' ? 'economic' : 'functional'
  area_klass = area == 'economic' ? GobiertoBudgets::EconomicArea : GobiertoBudgets::FunctionalArea
  code = row[3]
  level = row[4].to_i
  amount = row[6].to_f
  next if amount == 0

  if code.length > 3
    preffix = code[0..2]
    suffix = code[4..-1]
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

  if area_klass.all_items[kind][code].nil?
    missing[area][kind] ||= {}
    missing[area][kind][code] = row[5]
  end
end

puts missing.to_yaml
