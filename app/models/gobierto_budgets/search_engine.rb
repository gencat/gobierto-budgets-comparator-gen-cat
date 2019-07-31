module GobiertoBudgets
  class SearchEngine
    def self.client
      @client ||= if Rails.application.secrets.elastic1_url.present? && Rails.application.secrets.elastic2_url
                    Elasticsearch::Client.new log: false,
                                              hosts: [Rails.application.secrets.elastic1_url, Rails.application.secrets.elastic2_url],
                                              randomize_hosts: true,
                                              retry_on_failure: 3,
                                              resurrect_after: 10,
                                              request_timeout: 3
                  else
                    Elasticsearch::Client.new log: false, url: Rails.application.secrets.elastic_url
                  end
    end
  end
end
