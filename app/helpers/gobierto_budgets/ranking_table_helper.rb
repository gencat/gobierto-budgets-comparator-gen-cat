module GobiertoBudgets
  module RankingTableHelper

    def filter_link_path(filter_kind)
      gobierto_budgets_places_ranking_path(
        @year,
        @kind,
        @area_name,
        filter_kind,
        code: @code,
        ine_code: params[:ine_code],
        f: params[:f]
      )
    end

    def filter_selected?(filter_key)
      @variable == filter_key
    end

  end
end
