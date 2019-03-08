module GobiertoBudgets
  module CommonQueryBehavior
    extend ActiveSupport::Concern

    included do

      def self.append_ine_codes(terms, ine_codes)
        return unless ine_codes.any?

        terms << [{ terms: { ine_code: ine_codes } }]
      end

    end

  end
end
