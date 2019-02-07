module GobiertoBudgets
  class AssociatedEntity < ActiveRecord::Base

    self.table_name = "gobierto_budgets_associated_entities"

    validates :name, presence: true, uniqueness: { scope: :ine_code }
    validates :slug, presence: true, uniqueness: true # Can't scope on ine_code, URLs just pass one parameter
    validates :entity_id, presence: true, uniqueness: { scope: :ine_code }
    validates :ine_code, presence: true

    scope :by_place, ->(place) { where(ine_code: place.id) }

    before_validation :set_slug

    def total_expenses(year)
      BudgetTotal.budgeted_for(entity_id, year, BudgetLine::EXPENSE)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      nil
    end

    def total_income(year)
      BudgetTotal.budgeted_for(entity_id, year, BudgetLine::INCOME)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      nil
    end

    def combined_slug
      "#{associated_municipality.slug}/#{slug}"
    end

    private

    def associated_municipality
      INE::Places::Place.find(ine_code)
    end

    def set_slug
      return if slug.present?

      base_slug = name.parameterize
      new_slug = base_slug

      count = 2

      while self.class.exists?(slug: new_slug)
        new_slug = "#{base_slug}-#{count}"
        count += 1
      end

      self.slug = new_slug
    end

  end
end
