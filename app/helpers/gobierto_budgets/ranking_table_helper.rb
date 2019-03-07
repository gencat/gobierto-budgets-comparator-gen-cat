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

    def population_ranking?
      population_sorted? && @kind.nil?
    end

    def population_sorted?
      @variable == 'population'
    end

    def budgets_ranking?
      @kind.present?
    end

    def expense_filter?
      @kind == 'G'
    end

    def budget_line?
      @code.present?
    end

    def kind
      @kind == 'G' ? t('common.expenses') : t('common.incomes')
    end

    def page_title
      if population_sorted?
        t('.population_title', kind: kind, year: @year)
      elsif budget_line?
        t('.budget_line_title', kind: kind, budget_line: budget_line_denomination(@area_name, @code, @kind), year: @year)
      else
        t('.budget_lines_title', kind: kind, year: @year)
      end
    end

    def page_short_title
      if population_sorted?
        t('.population_short_title', kind: kind)
      elsif budget_line?
        t('.budget_line_short_title', kind: kind, budget_line: budget_line_denomination(@area_name, @code, @kind))
      else
        t('.budget_lines_short_title', kind: kind)
      end
    end

    def twitter_share_url
      "https://twitter.com/home?status=#{u twitter_share(page_short_title || @share_text, request.original_url)}"
    end

    def facebook_share_url
      "http://www.facebook.com/sharer/sharer.php?u=#{u request.original_url}"
    end

  end
end
