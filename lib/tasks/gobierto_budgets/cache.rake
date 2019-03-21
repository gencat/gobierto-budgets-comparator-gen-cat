namespace :gobierto_budgets do
  namespace :cache do
    desc "Warm cache"
    task warm_up: :environment do
      include GobiertoBudgets::ApplicationHelper
      include GobiertoBudgets::BudgetLineWidgetHelper

      def helpers
        ActionController::Base.helpers
      end

      def gobierto_budgets_places_ranking_path(*params)
        Rails.application.routes.url_helpers.gobierto_budgets_places_ranking_path(*params)
      end

      INE::Places::Place.all.in_groups_of(10) do |places_groups|
        threads = []

        places_groups.each do |place|
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
  end
end
