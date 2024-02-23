module GobiertoBudgets
  class PagesController < GobiertoBudgets::ApplicationController

    caches_page :home, :ranking, :deputations_ranking

    def home
    end

    def about
    end

    def pro
    end

    def faq
    end

    def legal_cookies
    end

    def legal_legal
    end

    def legal_privacy
    end

    def en
    end

    def request_access
      render layout: false
    end

    def ranking
      @places_collection = params[:places_collection]&.to_sym || :ine
      @ranking_paths = ranking_paths(
        ["I", "economic", "amount", 344],
        ["G", "functional", "amount_per_inhabitant", 336],
        ["G", "functional", "amount", 342],
        ["G", "functional", "amount_per_inhabitant", 165],
        ["G", "functional", "amount", 162],
        ["G", "functional", "amount_per_inhabitant", 44],
        ["I", "economic", "amount", 313],
        ["G", "functional", "amount_per_inhabitant", 171]
      )
    end

    def deputations_ranking
      @places_collection = params[:places_collection]&.to_sym || :ine
      @ranking_paths = ranking_paths(
        ["I", "economic", "amount", 391],
        ["G", "functional", "amount_per_inhabitant", 336],
        ["G", "functional", "amount", 341],
        ["G", "functional", "amount_per_inhabitant", 136],
        ["G", "functional", "amount", 231],
        ["G", "functional", "amount_per_inhabitant", 44],
        ["I", "economic", "amount", "220-07"],
        ["G", "functional", "amount_per_inhabitant", 414]
      )

      render :ranking
    end

    def map
      @year = params[:year].to_i
      unless GobiertoBudgets::SearchEngineConfiguration::Year.all.include?(@year)
        redirect_to gobierto_budgets_map_path(year: GobiertoBudgets::SearchEngineConfiguration::Year.last) and return false
      end
    end

    private

    def ranking_paths(*args_list)
      args_list.map do |args|
        gobierto_budgets_api_data_ranking_path(
          GobiertoBudgets::SearchEngineConfiguration::Year.last,
          *args,
          format: :json,
          only_municipalities: true,
          places_collection: @places_collection
        )
      end
    end
  end
end
