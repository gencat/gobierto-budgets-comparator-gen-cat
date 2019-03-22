module GobiertoBudgets
  class PlacesController < GobiertoBudgets::ApplicationController
    include RankingTableHelper
    include GobiertoBudgets::BudgetLineWidgetHelper

    layout :choose_layout
    before_action :set_current_organization, except: [:ranking, :compare, :redirect]
    before_action :get_params
    before_action :solve_income_area_mismatch, except: [:show]
    before_action :admin_user, only: [:intelligence]

    attr_reader :current_organization

    helper_method :current_organization

    def show
      if @year.nil?
        redirect_to gobierto_budgets_place_path(current_organization.combined_slug, SearchEngineConfiguration::Year.last) and return
      end

      @income_lines = BudgetLine.search(
        organization_id: current_organization.id,
        level: 1,
        year: @year,
        kind: BudgetLine::INCOME,
        type: 'economic'
      )

      @expense_lines = BudgetLine.search(organization_id: current_organization.id, level: 1, year: @year, kind: BudgetLine::EXPENSE, type: @area_name, recalculate_aggregations: true)
      @no_data = @income_lines['hits'].empty?

      load_featured_budget_line(allow_year_fallback: true)
      @amount_per_inhabitant_summary = budget_per_inhabitant_summary(default_budget_line_params)
      @amount_summary = amount_summary(default_budget_line_params)
      @percentage_over_total_summary = percentage_over_total_summary(default_budget_line_params)

      respond_to do |format|
        format.html
        format.js
      end
    end

    def execution
      @top_possitive_difference_income, @top_negative_difference_income = BudgetLine.top_differences(
        organization_id: current_organization.id,
        year: @year,
        kind: GobiertoBudgets::BudgetLine::INCOME,
        type: 'economic'
      )

      if @top_possitive_difference_income.empty?
        flash[:alert] = t('.no_data', year: @year)
        redirect_to gobierto_budgets_place_execution_path(current_organization.combined_slug, @year.to_i - 1) and return
      end

      @top_possitive_difference_expending_economic, @top_negative_difference_expending_economic = GobiertoBudgets::BudgetLine.top_differences(
        organization_id: current_organization.id,
        year: @year,
        kind: GobiertoBudgets::BudgetLine::EXPENSE,
        type: 'economic'
      )
      @top_possitive_difference_expending_functional, @top_negative_difference_expending_functional = GobiertoBudgets::BudgetLine.top_differences(
        organization_id: current_organization.id,
        year: @year,
        kind: GobiertoBudgets::BudgetLine::EXPENSE,
        type: 'functional'
      )
    end

    def debt_alive
    end

    def budget
      @level = (params[:parent_code].present? ? params[:parent_code].length + 1 : 1)

      options = {
        organization_id: current_organization.id,
        level: @level,
        year: @year,
        kind: @kind,
        type: @area_name
      }

      options[:parent_code] = params[:parent_code] if params[:parent_code].present?

      @budget_lines = GobiertoBudgets::BudgetLine.search(options)

      respond_to do |format|
        format.json do
          data_line = GobiertoBudgets::Data::Treemap.new place: current_organization, year: @year, kind: @kind, type: @area_name, parent_code: params[:parent_code]
          render json: data_line.generate_json
        end
        format.js
      end
    end

    # /places/compare/:slug_list/:year/:kind/:area
    def compare
      @places = get_places params[:slug_list]
      redirect_to gobierto_budgets_compare_path if @places.empty?

      @totals = GobiertoBudgets::BudgetTotal.for @places.map(&:id), @year
      @population = GobiertoBudgets::Population.for @places.map(&:id), @year
      if @population.empty?
        @population = GobiertoBudgets::Population.for @places.map(&:id), @year - 1
      end

      @compared_level = (params[:parent_code].present? ? params[:parent_code].length + 1 : 1)
      options = { ine_codes: @places.map(&:id), year: @year, kind: @kind, level: @compared_level, type: @area_name }

      if @compared_level > 1
        @budgets_and_ancestors = GobiertoBudgets::BudgetLine.compare_with_ancestors(options.merge(parent_code: params[:parent_code]))
        @budgets_compared = @budgets_and_ancestors.select {|bl| bl['parent_code'] == params[:parent_code]}
        @parent_compared = @budgets_and_ancestors.select {|bl| bl['code'] == params[:parent_code] }
      else
        @budgets_compared = @budgets_and_ancestors = GobiertoBudgets::BudgetLine.compare(options)
      end
    end

    def ranking
      @filters = params[:f]
      @per_page = GobiertoBudgets::Ranking.per_page
      @page = params[:page] ? params[:page].to_i : 1
      render_404 and return if @page <= 0

      @compared_level = params[:code] ? (params[:code].include?('-') ? params[:code].split('-').first.length : params[:code].length) : 0

      @ranking_items = GobiertoBudgets::Ranking.query({
        year: @year,
        variable: @variable,
        page: @page,
        code: @code,
        kind: @kind,
        area_name: @area_name,
        filters: @filters
      })

      respond_to do |format|
        format.html
        format.js
      end
    end

    def intelligence
    end

    def redirect
      @current_organization = Organization.new(organization_id: params[:ine_code])
      year = params[:year] || ::GobiertoBudgets::SearchEngineConfiguration::Year.last
      if current_organization.present?
        redirect_to gobierto_budgets_place_path(current_organization.combined_slug, year)
      end
    end

    private

    def get_params
      @kind = ( %w{income i}.include?(params[:kind].downcase) ? GobiertoBudgets::BudgetLine::INCOME : GobiertoBudgets::BudgetLine::EXPENSE ) if action_name != 'show' && params[:kind]
      @kind ||= GobiertoBudgets::BudgetLine::EXPENSE if action_name == 'ranking'
      @area_name = params[:area] || 'functional'
      @year = params[:year].present? ? params[:year].to_i : nil
      @code = params[:code]
      if params[:variable].present?
        @variable = params[:variable]
        render_404 and return unless valid_variables.include?(@variable)
      end
    end

    def solve_income_area_mismatch
      area = (params[:area].present? ? params[:area].downcase : '')
      kind = (params[:kind].present? ? params[:kind].downcase : '')
      if %w{income i}.include?(kind) && area == 'functional'
        redirect_to url_for params.merge(area: 'economic', kind: 'I') and return
      end
    end

    def get_places(slug_list)
      slug_list.split(':').map {|slug| INE::Places::Place.find_by_slug slug}.compact
    end

    def valid_variables
      ['amount','amount_per_inhabitant','population']
    end

    def set_current_organization
      @current_organization = if params[:slug]
                                Organization.new(slug: params[:slug])
                              elsif params[:organization_id]
                                Organization.new(id: params[:organization_id])
                              end
      render_404 and return if @current_organization.nil? || (@current_organization.place.nil? && @current_organization.associated_entity.nil?)
    end

  end
end
