# frozen_string_literal: true

module GobiertoBudgets
  class FeaturedBudgetLinesController < GobiertoBudgets::ApplicationController

    include GobiertoBudgets::ApplicationHelper
    include GobiertoBudgets::BudgetLineWidgetHelper

    before_action(
      :set_current_organization,
      :override_response_headers
    )

    attr_accessor :current_organization
    helper_method :current_organization

    def show
      respond_to do |format|
        format.js do
          @year = params[:year].to_i

          load_featured_budget_line

          if featured_budget_line?
            @amount_per_inhabitant_summary = budget_per_inhabitant_summary(default_budget_line_params)
            @amount_summary = amount_summary(default_budget_line_params)
            @percentage_over_total_summary = percentage_over_total_summary(default_budget_line_params)

            render(:show)
          else
            head(:not_found)
          end
        end
      end
    end

    def embed
      @year = current_year

      begin
        retries ||= 0
        load_featured_budget_line(allow_year_fallback: true)

        if featured_budget_line?
          @amount_per_inhabitant_summary = budget_per_inhabitant_summary(default_budget_line_params)
          @amount_summary = amount_summary(default_budget_line_params)
          @percentage_over_total_summary = percentage_over_total_summary(default_budget_line_params)
        end
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        retry if (retries += 1) < 10
      end

      respond_to do |format|
        format.html { @code.present? ? render(action: "embed", layout: "embed") : render_404 }
        format.js { @code.present? ? render(:show) : head(:not_found) }
      end
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

    def override_response_headers
      response.headers.delete "X-Frame-Options"
    end

    def current_year
      GobiertoBudgets::SearchEngineConfiguration::Year.last
    end
  end
end
