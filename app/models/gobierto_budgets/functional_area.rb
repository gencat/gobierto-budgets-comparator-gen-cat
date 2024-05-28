module GobiertoBudgets
  class FunctionalArea
    include GobiertoBudgetsData::GobiertoBudgets::Describable
    include GobiertoBudgetsData::GobiertoBudgets::Searchable

    def self.area_name
      "functional"
    end
  end
end
