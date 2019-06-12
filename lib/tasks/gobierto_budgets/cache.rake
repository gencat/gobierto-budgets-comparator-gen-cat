namespace :gobierto_budgets do
  namespace :cache do
    desc "Warm cache"
    task warm_up: :environment do
      include GobiertoBudgets::ApplicationHelper
      include GobiertoBudgets::BudgetLineWidgetHelper

      def helpers
        ActionController::Base.helpers
      end

      GobiertoBudgets::Population.for_year(2018).in_groups_of(10) do |places_groups|
        threads = []

        places_groups.each do |place_info|
          place = INE::Places::Place.find(place_info["organization_id"])
          threads << Thread.new do
            define_method(:current_organization) do
              place
            end

            puts "Current Organization: #{current_organization.name} - #{current_organization.id}"

            year = 2018
            area_name = "functional"
            kind = GobiertoBudgets::BudgetLine::EXPENSE

            results = GobiertoBudgets::BudgetLine.search(
              kind: kind,
              year: year,
              organization_id: place.id,
              type: area_name,
              range_hash: {
                level: { ge: 3 },
                amount_per_inhabitant: { gt: 0 }
              }
            )["hits"]

            results.each do |result|
              params = { year: year, kind: kind, area: area_name, code: result["code"] }
              budget_per_inhabitant_summary(params)
              amount_summary(params)
              percentage_over_total_summary(params)
            end
          end
        end

        threads.each(&:join)
      end
    end

    desc "Clear small municipalities budget lines cache"
    task clean_small_budget_lines: :environment do
      GobiertoBudgets::Population.for_year(2018)[4000..-1].each do |place_info|
        place = INE::Places::Place.find(place_info["organization_id"])
        FileUtils.rm_rf(Rails.root.join("public/cache/budget_lines/#{place.slug}"))
      end
    end
  end
end
