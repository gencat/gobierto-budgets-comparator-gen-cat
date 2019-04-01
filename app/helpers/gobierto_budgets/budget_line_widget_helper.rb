# frozen_string_literal: true

module GobiertoBudgets
  module BudgetLineWidgetHelper
    extend ActiveSupport::Concern

    include GobiertoBudgets::ApplicationHelper

    private

    def featured_budget_line?
      @code.present?
    end

    def load_featured_budget_line(params = {})
      @area_name = "functional"
      @kind = GobiertoBudgets::BudgetLine::EXPENSE

      results = featured_budget_line_candidates

      if params[:allow_year_fallback]
        until results.any? || (@year < Date.today.year - 2)
          @year -= 1
          results = featured_budget_line_candidates
        end
      end

      @code = results.any? ? results.sample["code"] : nil
    end

    def featured_budget_line_candidates
      GobiertoBudgets::BudgetLine.search(
        kind: @kind,
        year: @year,
        organization_id: @current_organization.id,
        type: @area_name,
        range_hash: {
          level: { ge: 3 },
          amount_per_inhabitant: { gt: 0 }
        }
      )["hits"]
    end

    def default_budget_line_params
      { year: @year, kind: @kind, area: @area_name, code: @code }
    end

    def budget_per_inhabitant_summary(params)
      year = params[:year]
      kind = params[:kind]
      area = params[:area]
      code = params[:code]

      title = if kind == "G"
                I18n.t("gobierto_budgets.api.data.budget_per_inhabitant.expenses_per_inhabitant")
              else
                I18n.t("gobierto_budgets.api.data.budget_per_inhabitant.income_per_inhabitant")
              end

      Rails.cache.fetch(elasticsearch_query_cache_key(__method__, params)) do
        budget_data = budget_data(params.merge(field: "amount_per_inhabitant"))
        budget_data_previous_year = budget_data(params.merge(
          year: year - 1,
          field: "amount_per_inhabitant",
          ranking: false
        ))
        position = budget_data[:position].to_i
        sign = sign(budget_data[:value], budget_data_previous_year[:value])

        {
          sign: sign,
          title: title,
          value: format_currency(budget_data[:value]),
          delta_percentage: helpers.number_with_precision(delta_percentage(budget_data[:value], budget_data_previous_year[:value]), precision: 2),
          ranking_position: position,
          ranking_total_elements: helpers.number_with_precision(budget_data[:total_elements], precision: 0),
          ranking_url: gobierto_budgets_places_ranking_path(
            year,
            kind,
            area,
            "amount_per_inhabitant",
            code.parameterize,
            page: GobiertoBudgets::Ranking.page_from_position(position),
            ine_code: current_organization.ine_code
          )
        }
      end
    end

    def amount_summary(params)
      year = params[:year]
      kind = params[:kind]
      area = params[:area]
      code = params[:code]

      category_name = kind == 'G' ? I18n.t('common.expense').capitalize : I18n.t('common.income').capitalize

      Rails.cache.fetch(elasticsearch_query_cache_key(__method__, params)) do
        budget_data = budget_data(params.merge(field: "amount"))
        budget_data_previous_year = budget_data(params.merge(
          year: year - 1,
          field: "amount",
          ranking: false
        ))
        position = budget_data[:position].to_i
        sign = sign(budget_data[:value], budget_data_previous_year[:value])

        {
          title: category_name,
          sign: sign,
          value: format_currency(budget_data[:value]),
          delta_percentage: helpers.number_with_precision(delta_percentage(budget_data[:value], budget_data_previous_year[:value]), precision: 2),
          ranking_position: position,
          ranking_total_elements: helpers.number_with_precision(budget_data[:total_elements], precision: 0),
          ranking_url: gobierto_budgets_places_ranking_path(
            year,
            kind,
            area,
            "amount",
            code.parameterize,
            page: GobiertoBudgets::Ranking.page_from_position(position),
            ine_code: current_organization.ine_code
          )
        }
      end
    end

    def percentage_over_total_summary(params)
      year = params[:year]
      kind = params[:kind]
      area = params[:area]
      code = params[:code]

      Rails.cache.fetch(elasticsearch_query_cache_key(__method__, params)) do
        begin
          result = GobiertoBudgets::SearchEngine.client.get(
            index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast,
            type: area,
            id: [current_organization.id, year, code, kind].join("/")
          )

          amount = result['_source']['amount'].to_f

          result = GobiertoBudgets::SearchEngine.client.get(
            index: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_forecast,
            type: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type,
            id: [current_organization.id, year, BudgetLine::EXPENSE].join('/')
          )

          total_amount = result['_source']['total_budget'].to_f

          percentage = (amount.to_f * 100)/total_amount
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          percentage = 0
        end

        {
          title: I18n.t('gobierto_budgets.featured_budget_lines.show.percentage_over_total'),
          value: "#{helpers.number_with_precision(percentage, precision: 2, strip_insignificant_zeros: true)}%",
          sign: sign(percentage)
        }
      end
    end

    def budget_data(params = {})
      year = params[:year]
      kind = params[:kind]
      area = params[:area]
      code = params[:code]
      field = params[:field]
      ranking = params[:ranking] != false

      result = GobiertoBudgets::SearchEngine.client.get index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, type: area, id: [current_organization.id, year, code, kind].join('/')
      value = result['_source'][field]

      total_elements = 0
      position = 0

      if ranking
        opts = { year: year, code: code, kind: kind, area_name: area, variable: field, place: current_organization&.place, organization_id: current_organization.id }
        position, total_elements = BudgetLine.place_position_in_ranking(opts)
      end

      return {
        value: value,
        position: position,
        total_elements: total_elements
      }
    end

    def delta_percentage(value, old_value)
      return "" if value.nil? || old_value.nil?

      ((value.to_f - old_value.to_f)/old_value.to_f) * 100
    end

    def elasticsearch_query_cache_key(method_name, params)
      "#{method_name}-#{current_organization.id}-#{params[:year]}-#{params[:kind]}-#{params[:area]}-#{params[:code]}"
    end

  end
end
