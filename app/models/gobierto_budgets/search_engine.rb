# frozen_string_literal: true

module GobiertoBudgets
  class SearchEngine
    def self.client
      @client ||= Elasticsearch::Client.new log: true, url: Rails.application.secrets.elastic_url
    end
  end
end
