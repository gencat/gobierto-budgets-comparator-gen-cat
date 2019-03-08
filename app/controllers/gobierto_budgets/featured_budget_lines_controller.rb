module GobiertoBudgets
  class FeaturedBudgetLinesController < GobiertoBudgets::ApplicationController

    before_action :set_current_organization, :set_featured_budget_line_attributes, :check_embedded

    attr_accessor :current_organization
    helper_method :current_organization

    def show
      @year = params[:year].to_i

      results = featured_budget_line_candidates(@kind, @year, @area_name)

      @code = results.sample["code"] if results.any?

      respond_to do |format|
        format.js { @code.present? ? render(:show) : head(:not_found) }
      end
    end

    # http://localhost:3000/featured_budget_lines/embed/28079
    def embed
      @year = 2018

      @current_organization = Organization.new(slug: "madrid")

      budget_lines = featured_budget_line_candidates(@kind, @year, @area_name)

      @budget_line = budget_lines.sample if budget_lines.any?
      @code = @budget_line["code"]

      render(action: "embed", layout: "embed")
    end

    private

    def set_current_organization
      @current_organization = if params[:organization_slug]
        Organization.new(slug: params[:organization_slug])
      elsif params[:organization_id]
        Organization.new(organization_id: params[:organization_id])
      end

      render_404 and return if @current_organization.nil? || (@current_organization.place.nil? && @current_organization.associated_entity.nil?)
    end

    def set_featured_budget_line_attributes
      @area_name = "functional"
      @kind = GobiertoBudgets::BudgetLine::EXPENSE
    end

    def featured_budget_line_candidates(kind, year, area_name)
      BudgetLine.search(
        kind: kind,
        year: year,
        organization_id: @current_organization.id,
        type: area_name,
        range_hash: {
          level: { ge: 3 },
          amount_per_inhabitant: { gt: 0 }
        }
      )["hits"]
    end

    def check_embedded
      @embedded = params[:embed]
    end

  end
end
