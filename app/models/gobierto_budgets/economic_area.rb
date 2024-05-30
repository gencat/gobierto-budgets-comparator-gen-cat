module GobiertoBudgets
  class EconomicArea
    include GobiertoBudgetsData::GobiertoBudgets::Describable
    include GobiertoBudgetsData::GobiertoBudgets::Searchable

    def self.area_name
      "economic"
    end
  end
end
