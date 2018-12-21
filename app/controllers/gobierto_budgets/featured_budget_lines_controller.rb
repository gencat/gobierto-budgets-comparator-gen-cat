module GobiertoBudgets
  class FeaturedBudgetLinesController < GobiertoBudgets::ApplicationController

    before_action :set_current_organization

    attr_accessor :current_organization
    helper_method :current_organization

    def show
      @year = params[:year].to_i
      @area_name = "functional"
      @kind = GobiertoBudgets::BudgetLine::EXPENSE

      results = BudgetLine.search(
        kind: @kind,
        year: @year,
        organization_id: current_organization.id,
        type: @area_name,
        range_hash: {
          level: { ge: 3 },
          amount_per_inhabitant: { gt: 0 }
        }
      )["hits"]

      @code = results.sample["code"] if results.any?

      respond_to do |format|
        format.js { @code.present? ? render(:show) : head(:not_found) }
      end
    end

    private

    def set_current_organization
      @current_organization = Organization.new(slug: params[:id])

      render_404 and return if @current_organization.nil? || (@current_organization.place.nil? && @current_organization.associated_entity.nil?)
    end

  end
end
