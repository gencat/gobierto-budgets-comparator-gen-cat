# frozen_string_literal: true

namespace :gobierto_budgets do
  namespace :data do
    desc "Import CSV with extra data"
    task :import_extra_data, [:csv_path] => [:environment] do |_t, args|
      csv_path = args[:csv_path]
      unless File.file?(csv_path)
        puts "[ERROR] No CSV file found: #{csv_path}"
        exit -1
      end

      # This file can be generated with the following SQL in datos.gobierto.es
      #
      #
      #
      # SELECT 2021 AS year,
      # d.place_id,
      # d.value AS Deuda,
      # SUM(p.total) AS Habitantes
      # FROM deuda_municipal d
      # INNER JOIN poblacion_edad_sexo p ON p.place_id = d.place_id AND p.sex = 'Total' AND p.year = 2021
      # GROUP BY d.place_id, d.value

      CSV.read(csv_path, headers: true).each do |row|
        year = row["year"].to_s
        population = row["habitantes"].to_i

        place_id = row["place_id"].to_i
        id = [place_id, year].join('/')
        place = INE::Places::Place.find(place_id)
        province_id = place.province.id.to_i
        autonomous_region_id = place.province.autonomous_region.id.to_i

        if row.headers.include?("deuda")
          debt = row["deuda"].to_f.round(2)
          item = {
            "organization_id" => place_id,
            "ine_code" => place_id,
            "year" => year,
            "value" => debt,
            "province_id" => province_id,
            "autonomy_id" => autonomous_region_id
          }

          debt_data = [
            {
              index: {
                _index: GobiertoBudgetsData::GobiertoBudgets::ES_INDEX_DATA,
                _type: GobiertoBudgetsData::GobiertoBudgets::DEBT_TYPE,
                _id: id,
                data: item
              }
            }
          ]

          GobiertoBudgetsData::GobiertoBudgets::SearchEngineWriting.client.bulk(body: debt_data)
          puts "[SUCCESS] Debt #{debt} for #{year} and place #{place.name}"
        end

        item = {
          "organization_id" => place_id,
          "ine_code" => place_id,
          "year" => year,
          "value" => population,
          "province_id" => province_id,
          "autonomy_id" => autonomous_region_id
        }

        population_data = [
          {
            index: {
              _index: GobiertoBudgetsData::GobiertoBudgets::ES_INDEX_DATA,
              _type: GobiertoBudgetsData::GobiertoBudgets::POPULATION_TYPE,
              _id: id,
              data: item
            }
          }
        ]
        GobiertoBudgetsData::GobiertoBudgets::SearchEngineWriting.client.bulk(body: population_data)

        puts "[SUCCESS] Population #{population} for #{year}"
      end
    end
  end
end
