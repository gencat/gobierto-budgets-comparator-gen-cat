module GobiertoBudgets
  class Organization

    attr_accessor :id, :place, :associated_entity

    def initialize(attributes)
      @places_collection_key = attributes[:places_collection]&.to_sym || :ine

      if (slug_param = attributes[:slug])
        (slug_param = slug_param.split("/").last) if slug_param.include?("/")

        if @place = ine_place? ? ::INE::Places::Place.find_by_slug(slug_param) : places_collection.find { |place| place.slug == slug_param }
          @id = @place.id
        elsif @associated_entity = AssociatedEntity.find_by(slug: slug_param)
          @id = @associated_entity.entity_id
        end
      elsif attributes[:organization_id]
        @id = attributes[:organization_id]
        @place = ine_place? ? ::INE::Places::Place.find(id) : places_collection.find { |place| place.id == id }
        @associated_entity = AssociatedEntity.find_by(id: id)
      end
    end

    def ine_place?
      @ine_place ||= @places_collection_key == :ine
    end

    def population?
      ine_place? || place.population?
    end

    def name
      city_council? ? @place.name : @associated_entity.name
    end

    def slug
      city_council? ? @place.slug : @associated_entity.slug
    end

    def associated_entities
      city_council? ? AssociatedEntity.by_place(place) : []
    end

    def parent_place_associated_entities
      city_council? ? [] : AssociatedEntity.by_place(associated_entity_place)
    end

    def places_collection
      @places_collection ||= PlaceDecorator.collection(@places_collection_key)
    end

    def autonomous_region_id
      if city_council?
        place.province.autonomous_region.id
      else
        associated_entity_place.province.autonomous_region.id
      end
    end

    def autonomous_region_name
      if city_council?
        place.province.autonomous_region.name
      else
        associated_entity_place.province.autonomous_region.name
      end
    end

    def province_id
      if city_council?
        place.province.id
      else
        associated_entity_place.province.id
      end
    end

    def province_name
      if city_council?
        place.province.name
      else
        associated_entity_place.province.name
      end
    end

    def parent_place_name
      associated_entity_place.name
    end

    def parent_place_slug
      associated_entity_place.slug
    end

    def city_council?
      @place.present?
    end

    # Meant to be nil for associated entities
    def ine_code
      city_council? ? place.id : nil
    end

    # Meant to return the underlying ine_code
    def place_id
      city_council? ? place.id : associated_entity_place.id
    end

    def combined_slug
      city_council? ? slug : "#{parent_place_slug}/#{slug}"
    end

    private

    def associated_entity_place
      ::INE::Places::Place.find(@associated_entity.ine_code) unless city_council?
    end

  end
end
