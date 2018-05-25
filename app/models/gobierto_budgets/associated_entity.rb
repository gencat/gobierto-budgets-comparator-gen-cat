module GobiertoBudgets
  class AssociatedEntity < ActiveRecord::Base

    self.table_name = "gobierto_budgets_associated_entities"

    validates :name, presence: true, uniqueness: { scope: :ine_code }
    validates :entity_id, presence: true, uniqueness: { scope: :ine_code }
    validates :ine_code, presence: true

    scope :by_place, ->(place) { where(ine_code: place.id) }

    def total_expenses(year)
      BudgetTotal.budgeted_for(entity_id, year, BudgetLine::EXPENSE)
    end

    def total_income(year)
      BudgetTotal.budgeted_for(entity_id, year, BudgetLine::INCOME)
    end

  end
end
