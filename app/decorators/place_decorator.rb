# frozen_string_literal: true

PLACES_COLLECTIONS = {
  ine: INE::Places::Place.all,
  deputation_eu: [
    OpenStruct.new(id: "48000DD000", province_id: 48, autonomous_region_id: 16, name: "Diputación Foral de Vizcaya", custom_place_id: "deputation_eu"),
    OpenStruct.new(id: "01000DD000", province_id: 1, autonomous_region_id: 16, name: "Diputación Foral de Alava", custom_place_id: "deputation_eu"),
    OpenStruct.new(id: "20000DD000", province_id: 20, autonomous_region_id: 16, name: "Diputación Foral de Guipúzcoa", custom_place_id: "deputation_eu")
  ]
}

class PlaceDecorator
  attr_reader :id, :place
  delegate :name, to: :place

  def self.collection(key)
    key = key.to_sym
    raise "Invalid place_type #{key}. Valid place types: #{PLACES_COLLECTIONS.keys.join(", ")} " unless PLACES_COLLECTIONS.keys.include?(key)

    PLACES_COLLECTIONS[key].map do |place|
      new(place)
    end
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
    attributes["place_id"].present?
  end
end
