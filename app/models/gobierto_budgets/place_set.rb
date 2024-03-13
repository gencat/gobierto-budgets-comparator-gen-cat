# frozen_string_literal: true

module GobiertoBudgets
  class PlaceSet
    def initialize(options = {})
      @places_collection = options[:places_collection] || :ine
      @ine_codes = options[:ine_codes] || []
      @organization_ids = (options[:organization_ids] || default_organization_ids).map(&:to_s)

      if GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope?
        @places_scope = GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope
        @organizations_scope = GobiertoBudgets::SearchEngineConfiguration::Scopes.organization_ids&.map(&:to_s)
      end
    end

    def restrict(options = {})
      @ine_codes = @ine_codes & options[:ine_codes] if options[:ine_codes].present?
      @organization_ids = @organization_ids & options[:organization_ids].map(&:to_s) if options[:organization_ids].present?
    end

    def ine_codes
      return @ine_codes if @places_scope.blank?

      @ine_codes & @places_scope
    end

    def default_organization_ids
      return [] if @organization_ids == :ine

      PlaceDecorator.collection_organization_ids(@places_collection)
    end

    def organization_ids
      return @organization_ids if @organizations_scope.blank?

      @organization_ids & @organizations_scope
    end

    def associated_entity_ids
      return [] if ine_codes.blank?

      AssociatedEntity.where(ine_code: ine_codes).pluck(:entity_id)
    end

    def population_organization_id_conversions
      return if @places_collection == :ine

      organization_ids.each_with_object({}) do |organization_id, hash|
        hash[organization_id] = PlaceDecorator.find(organization_id, places_collection: @places_collection).population_organization_id
      end
    end
  end
end
