module GobiertoBudgets
  module Api
    class CategoriesController < ApplicationController
      caches_action :index

      def index
        kind = params[:kind]
        area = params[:area]
        render_404 and return if area == 'functional' and kind == 'I'

        if kind.nil? && area.nil?
          categories = {}
          [GobiertoBudgets::EconomicArea, GobiertoBudgets::FunctionalArea].each do |klass|
            area_name = (klass == GobiertoBudgets::EconomicArea) ? GobiertoBudgets::BudgetLine::ECONOMIC : GobiertoBudgets::BudgetLine::FUNCTIONAL
            [GobiertoBudgets::BudgetLine::INCOME, GobiertoBudgets::BudgetLine::EXPENSE].each do |kind|
              next if kind == GobiertoBudgets::BudgetLine::INCOME and klass == GobiertoBudgets::FunctionalArea

              categories[area_name] ||= {}
              categories[area_name][kind] = Hash[klass.all_items[kind].sort_by{ |k,v| k.to_f }]
            end
          end
        else
          klass = area == 'economic' ? GobiertoBudgets::EconomicArea : GobiertoBudgets::FunctionalArea
          categories = Hash[klass.all_items[kind].sort_by{ |k,v| k.to_f }]
        end


        respond_to do |format|
          format.json do
            render json: categories.to_json
          end
        end
      end

      def place
        @place = INE::Places::Place.find_by_slug params[:slug]
        @year = params[:year]
        @area = params[:area]
        @kind = params[:kind]

        klass = @area == 'economic' ? GobiertoBudgets::EconomicArea : GobiertoBudgets::FunctionalArea
        categories = Hash[klass.all_items[@kind].sort_by{ |k,v| k.to_f }]

        terms = [{term: { ine_code: @place.id }}, {term: { year: @year }}, {term: { kind: @kind }}]

        query = {
          query: {
            filtered: {
              filter: {
                bool: {
                  must: terms
                }
              }
            }
          },
          size: 10_000
        }

        response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, type: @area, body: query
        codes = response['hits']['hits'].map{|h| h['_source']['code'] }

        categories.delete_if{|k,_| !codes.include?(k) }

        respond_to do |format|
          format.json do
            render json: categories.to_json
          end
        end
      end
    end
  end
end
