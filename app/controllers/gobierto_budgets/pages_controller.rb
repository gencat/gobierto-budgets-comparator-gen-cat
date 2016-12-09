module GobiertoBudgets
  class PagesController < GobiertoBudgets::ApplicationController
    skip_before_action :authenticate, only: [:request_access]

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

    def map
      @year = params[:year]
    end

  end
end
