module GobiertoBudgets
  class BudgetLinesController < GobiertoBudgets::ApplicationController

    layout :choose_layout
    before_action :set_current_organization, :load_params

    attr_accessor :current_organization

    helper_method :current_organization

    def show
    end

    def feedback
      @question_id = params[:question_id].to_i
      render_404 and return unless [1,2].include?(@question_id)

      render 'show'
    end

    private

    def set_current_organization
      @current_organization = Organization.new(slug: params[:slug])
    end

    def load_params
      @year = params[:year]
      @code = params[:code]
      @kind = ( %w{income i}.include?(params[:kind].downcase) ? GobiertoBudgets::BudgetLine::INCOME : GobiertoBudgets::BudgetLine::EXPENSE )
      @area_name = params[:area] || 'economic'

      options = { organization_id: current_organization.id, year: @year, kind: @kind, type: @area_name }

      @budget_line = BudgetLine.new(
        year: @year,
        kind: @kind,
        place_id: current_organization.place_id,
        area_name: @area_name, code: @code
      )

      @parent_line = BudgetLine.find(options.merge(code: @code))
      render_404 and return if @parent_line.nil?
      @budget_lines = BudgetLine.search(options.merge(parent_code: @code))
    end

  end
end
