# frozen_string_literal: true

PLACES_COLLECTIONS = {
  ine: INE::Places::Place.all,
  deputation_eu: [
    OpenStruct.new(id: "48000DD000", province_id: 48, autonomous_region_id: 16, name: "Diputación Foral de Vizcaya", custom_place_id: "deputation_eu", slug: "dip-bizkaia"),
    OpenStruct.new(id: "01000DD000", province_id: 1, autonomous_region_id: 16, name: "Diputación Foral de Alava", custom_place_id: "deputation_eu", slug: "dip-alava"),
    OpenStruct.new(id: "20000DD000", province_id: 20, autonomous_region_id: 16, name: "Diputación Foral de Guipúzcoa", custom_place_id: "deputation_eu", slug: "dip-gipuzkoa")
  ]
}

PLACES_TYPES = {
  ine: "Place",
  deputation_eu: "Deputation"
}

class PlaceDecorator
  attr_reader :id, :place
  delegate :name, :slug, to: :place

  def self.collection(key)
    key = key.to_sym
    raise "Invalid place_type #{key}. Valid place types: #{PLACES_COLLECTIONS.keys.join(", ")} " unless PLACES_COLLECTIONS.keys.include?(key)

    PLACES_COLLECTIONS[key].map do |place|
      new(place)
    end
  end

  def self.collection_organization_ids(key)
    key = key.to_sym
    raise "Invalid place_type #{key}. Valid place types: #{PLACES_COLLECTIONS.keys.join(", ")} " unless PLACES_COLLECTIONS.keys.include?(key)

    PLACES_COLLECTIONS[key].map(&:id)
  end

  def self.find(id, places_collection: :ine)
    key = places_collection&.to_sym || :ine
    raise "Invalid place_type #{key}. Valid place types: #{PLACES_COLLECTIONS.keys.join(", ")} " unless PLACES_COLLECTIONS.keys.include?(key)

    place = key == :ine ? INE::Places::Place.find(id) : PLACES_COLLECTIONS[key].find { |item| item.id == id }
    return if place.blank?

    new(place)
  end

  def self.find_by_slug(slug, places_collection: :ine)
    key = places_collection&.to_sym || :ine
    return unless PLACES_COLLECTIONS.keys.include?(key)

    place = key == :ine ? INE::Places::Place.find_by_slug(slug) : PLACES_COLLECTIONS[key].find { |item| item.slug == slug }
  end

  def self.find_in_all_collections(id)
    PLACES_COLLECTIONS.keys.map do |places_collection|
      find(id, places_collection:)
    end.compact.first
  end

  def self.population_type_index(places_collection_key)
    return GobiertoBudgets::SearchEngineConfiguration::Data.type_population_province if places_collection_key&.to_sym == :deputation_eu

    GobiertoBudgets::SearchEngineConfiguration::Data.type_population
  end

  def self.place_type(key)
    PLACES_TYPES[key.to_sym] || PLACES_TYPES[:ine]
  end

  def initialize(place)
    @place = place
    @id = place.id
  end

  def attributes
    @attributes ||= {
      "place_id" => numeric_id? ? id.to_i : nil,
      "province_id" => (place.try(:province_id) || place.province.id)&.to_i,
      "autonomous_region_id" => (place.try(:autonomous_region_id) || place.province.autonomous_region.id)&.to_i
    }
  end

  def province
    return place.province if place.respond_to?(:province)
    INE::Places::Province.find(@place.province_id) if place.respond_to?(:province_id)
  end

  def custom_place_id
    place.try(:custom_place_id)
  end

  def code
    return id unless numeric_id?

    "#{format("%.5i", id)}AA000"
  end

  def numeric_id?
    id.is_a?(Numeric) || /\A\d+\z/.match?(id.to_s.strip)
  end

  def population?
    population_key.present?
  end

  def debt?
    @place.debt
  end

  def population_key
    @population_key ||= %w(place_id province_id autonomous_region_id).find { |key| attributes[key].present? }
  end

  def population_organization_id
    case population_key
    when "place_id"
      attributes[population_key]&.to_i || place.id.to_i
    when "province_id"
      "province-#{province.id}"
    when "autonomous_region_id"
      "autonomy-#{autonomous_region.id}"
    end
  end

  def population_place_ids
    case population_key
    when "place_id"
      [attributes[population_key]&.to_s || place.id]
    when "province_id"
      province.places.map(&:id)
    when "autonomous_region_id"
      autonomous_region.provinces.map { |province| province.places.map(&:id) }.flatten
    else
      []
    end
  end
end
