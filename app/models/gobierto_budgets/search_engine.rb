module GobiertoBudgets
  class SearchEngine
    def self.client
      @client ||= if Rails.application.credentials.elastic1_url.present? && Rails.application.credentials.elastic2_url
                    Elasticsearch::Client.new log: false,
                                              hosts: [Rails.application.credentials.elastic1_url, Rails.application.credentials.elastic2_url],
                                              randomize_hosts: true,
                                              retry_on_failure: 3,
                                              resurrect_after: 10,
                                              request_timeout: 3
                  else
                    Elasticsearch::Client.new log: false, url: Rails.application.credentials.elastic_url
                  end
    end
  end
end
