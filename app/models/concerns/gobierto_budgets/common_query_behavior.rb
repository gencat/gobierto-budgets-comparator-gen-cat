module GobiertoBudgets
  module CommonQueryBehavior
    extend ActiveSupport::Concern

    included do

      def self.append_to_terms(terms, items, key = :ine_code)
        return if items.compact.blank?

        terms << [{ terms: { key => items.compact } }]
      end

      def append_to_terms(terms, items, key = :ine_code)
        self.class.append_to_terms(terms, items, key)
      end

      def self.append_ine_codes(terms, ine_codes) = append_to_terms(terms, ine_codes)

      def append_ine_codes(terms, ine_codes) = append_to_terms(terms, ine_codes)

      def self.append_organization_ids(terms, organization_ids) = append_to_terms(terms, organization_ids, :organization_id)

      def append_organization_ids(terms, organization_ids) = append_to_terms(terms, organization_ids, :organization_id)
    end
  end
end
