module GobiertoBudgets
  class AssociatedEntity < ActiveRecord::Base

    self.table_name = "gobierto_budgets_associated_entities"

    validates :name, presence: true, uniqueness: { scope: :ine_code }
    validates :entity_id, presence: true, uniqueness: { scope: :ine_code }
    validates :ine_code, presence: true

  end
end
