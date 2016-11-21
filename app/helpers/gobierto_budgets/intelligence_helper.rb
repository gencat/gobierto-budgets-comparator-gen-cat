module GobiertoBudgets
  module IntelligenceHelper
    def filter_variables_for_means(selected = nil)
      select_tag("variable", options_for_select([['Media provincial', 'province'], ['Media autonómica', 'autonomy'], ['Media nacional', 'country']], selected))
    end
  end
end
