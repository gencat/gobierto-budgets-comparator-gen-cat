module GobiertoBudgets
  module Api
    class GlobalDataController < ApplicationController
      include GobiertoBudgets::ApplicationHelper

      caches_action :total_budget, :total_budget_execution, :population, :total_budget_per_inhabitant, :debt, cache_path: ->(c) { { locale: I18n.locale} }

      def total_budget
        year = params[:year].to_i
        total_budget_data = total_budget_data(year, 'total_budget')
        total_budget_data_previous_year = total_budget_data(year - 1, 'total_budget')
        sign = sign(total_budget_data, total_budget_data_previous_year)

        respond_to do |format|
          format.json do
            render json: {
              title: t('.total_expenses'),
              sign: sign,
              value: helpers.number_to_currency(total_budget_data, precision: 0, strip_insignificant_zeros: true),
              delta_percentage: helpers.number_with_precision(delta_percentage(total_budget_data, total_budget_data_previous_year), precision: 2),
              ranking_position: nil,
              ranking_total_elements: nil,
              ranking_url: nil
            }.to_json
          end
        end
      end


      def total_budget_per_inhabitant
        year = params[:year].to_i
        total_budget_data = total_budget_data(year, 'total_budget')
        population_year = year
        population_year -= 1 if GobiertoBudgets::SearchEngineConfiguration::Year.fallback_year?(year)
        population = total_population(population_year)
        total_budget_data = total_budget_data / population
        total_budget_data_previous_year = total_budget_data(year - 1, 'total_budget')
        population_previous_year = total_population(year - 1)
        total_budget_data_previous_year = total_budget_data_previous_year / population_previous_year
        sign = sign(total_budget_data, total_budget_data_previous_year)

        respond_to do |format|
          format.json do
            render json: {
              title: t('.expenses_per_inhabitant'),
              sign: sign,
              value: helpers.number_to_currency(total_budget_data, precision: 0, strip_insignificant_zeros: true),
              delta_percentage: helpers.number_with_precision(delta_percentage(total_budget_data, total_budget_data_previous_year), precision: 2),
              ranking_position: nil,
              ranking_total_elements: nil,
              ranking_url: nil
            }.to_json
          end
        end
      end

      def debt
        year = params[:year].to_i

        no_data_this_year = false
        debt_year = total_debt(year)
        if debt_year.nil?
          year -= 1
          debt_year = total_debt(year)
          no_data_this_year = year
        end
        debt_previous_year = total_debt(year - 1)
        sign = sign(debt_year, debt_previous_year)

        respond_to do |format|
          format.json do
            render json: {
              title: t('.debt'),
              sign: nil,
              delta_percentage: helpers.number_with_precision(delta_percentage(debt_previous_year, debt_year), precision: 2),
              value: helpers.number_to_currency(debt_year, precision: 0, strip_insignificant_zeros: true),
              no_data_this_year: no_data_this_year
            }.to_json
          end
        end
      end

      def population
        year = params[:year].to_i

        no_data_this_year = false
        population_year = total_population(year)
        if population_year.nil?
          year -= 1
          population_year = total_population(year)
          no_data_this_year = year
        end
        population_previous_year = total_population(year - 1)
        sign = sign(population_year, population_previous_year)

        respond_to do |format|
          format.json do
            render json: {
              title: t('.population'),
              sign: nil,
              delta_percentage: helpers.number_with_precision(delta_percentage(population_previous_year, population_year), precision: 2),
              value: helpers.number_with_delimiter(population_year.to_i, precision: 0, strip_insignificant_zeros: true),
              no_data_this_year: no_data_this_year
            }.to_json
          end
        end
      end

      def total_budget_execution
        year = params[:year].to_i
        year -= 1 if GobiertoBudgets::SearchEngineConfiguration::Year.fallback_year?(year)
        total_budget_data_planned = total_budget_data(year, 'total_budget')
        total_budget_data_executed = total_budget_data_executed(year, 'total_budget')
        diff = total_budget_data_executed - total_budget_data_planned rescue ""
        sign = sign(total_budget_data_executed, total_budget_data_planned)
        diff = format_currency(diff) if diff.is_a?(Float)

        respond_to do |format|
          format.json do
            render json: {
              title: t('.planned_vs_executed'),
              sign: sign,
              delta_percentage: helpers.number_with_precision(delta_percentage(total_budget_data_executed, total_budget_data_planned), precision: 2),
              value: diff
            }.to_json
          end
        end
      end

      private

      def delta_percentage(value, old_value)
        return "" if value.nil? || old_value.nil?
        ((value.to_f - old_value.to_f)/old_value.to_f) * 100
      end

      def total_budget_data(year, field)
        terms = [ {term: { year: year }}, {term: { kind: GobiertoBudgets::BudgetLine::EXPENSE }} ]

        if GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope?
          ine_codes = GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope
          terms << {terms: { ine_code: ine_codes.compact }} if ine_codes.any?
        end

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
          size: 10_000,
          _source: false,
          aggs: {
            total: {
              sum: {
                field: field
              }
            }
          }
        }

        value = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_forecast, type: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type, body: query
        value['aggregations']['total']['value'].to_f.round(2)
      end

      def total_budget_data_executed(year, field)
        terms = [
          {term: { year: year }},
          {term: { kind: GobiertoBudgets::BudgetLine::EXPENSE }}
        ]

        if GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope?
          ine_codes = GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope
          terms << {terms: { ine_code: ine_codes.compact }} if ine_codes.any?
        end

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
          size: 10_000,
          _source: false,
          aggs: {
            total: {
              sum: {
                field: field
              }
            }
          }
        }

        value = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_executed, type: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type, body: query
        value['aggregations']['total']['value'].to_f.round(2)
      end


      def total_population(year)
        terms = [ {term: { year: year }} ]

        if GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope?
          ine_codes = GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope
          terms << {terms: { ine_code: ine_codes.compact }} if ine_codes.any?
        end

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
          size: 10_000,
          _source: false,
          aggs: {
            total: {
              sum: {
                field: 'value'
              }
            }
          }
        }

        value = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::Data.index, type: GobiertoBudgets::SearchEngineConfiguration::Data.type_population, body: query
        return nil if value['hits']['total'] == 0
        value['aggregations']['total']['value']
      end

      def total_debt(year)
        terms = [ {term: { year: year }} ]

        if GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope?
          ine_codes = GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope
          terms << {terms: { ine_code: ine_codes.compact }} if ine_codes.any?
        end

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
          size: 10_000,
          _source: false,
          aggs: {
            total: {
              sum: {
                field: 'value'
              }
            }
          }
        }

        value = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::Data.index, type: GobiertoBudgets::SearchEngineConfiguration::Data.type_debt, body: query
        return nil if value['hits']['total'] == 0
        value['aggregations']['total']['value'].to_f.round(2)
      end
    end
  end
end
