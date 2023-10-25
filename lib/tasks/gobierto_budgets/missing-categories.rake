# frozen_string_literal: true

namespace :gobierto_budgets do
  namespace :missing_categories do
    desc "Check missing categories"
    task check: :environment do
      missing = []
      ::GobiertoBudgetsData::GobiertoBudgets::ALL_KINDS.each do |kind|
        [::GobiertoBudgetsData::GobiertoBudgets::ECONOMIC_AREA_NAME, ::GobiertoBudgetsData::GobiertoBudgets::FUNCTIONAL_AREA_NAME].each do |area_name|

          missing_names = ::GobiertoBudgetsData::GobiertoBudgets::BudgetLine.all(
            kind: kind,
            area_name: area_name
          ).select do |bl|
            area_klass = (bl.area_name == "economic") ? ::GobiertoBudgets::EconomicArea : ::GobiertoBudgets::FunctionalArea
            area_items_of_kind = area_klass.all_items[bl.kind]

            !area_items_of_kind.present? || area_items_of_kind[bl.code].blank?
          end

          missing = missing.concat(missing_names) if missing_names.any?
        end
      end

      if missing.empty?
        puts " - No missing category names for gobierto budgets comparator"
        exit(0)
      else
        puts " - Found #{missing.size} missing names"
      end

      file_name = "/tmp/missing_categories_budgets_comparator.csv"

      CSV.open(file_name, "wb") do |csv|
        csv << %W{ Area Tipo Codigo }
        while missing.any?
          budget_line = missing.pop
          line_to_write = [budget_line.area_name, budget_line.kind, budget_line.code]
          csv << line_to_write
          missing.delete_if do |other_budget_line|
            if other_budget_line.id.split("/")[2..-1] == budget_line.id.split("/")[2..-1]
              missing.delete(other_budget_line)
            end
          end
        end
      end

      puts
      puts " - Written file #{file_name}"
      puts
    end
  end
end
