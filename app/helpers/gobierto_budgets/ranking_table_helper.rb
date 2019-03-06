module GobiertoBudgets
  module RankingTableHelper

    def column_filters
      [
        { key: 'population', literal: t('.inhabitants') },
        { key: 'amount_per_inhabitant', literal: "#{kind_literal(@kind)}/hab", tooltip: "Gasto por habitante" },
        { key: 'amount', literal: "#{kind_literal(@kind)} #{I18n.t('common.totals')}" }
      ]
    end

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

    def formatted_amount(amount)
      if amount.to_i.zero?
        "-"
      else
        number_to_currency(amount, strip_insignificant_zeros: true)
      end
    end

  end
end
