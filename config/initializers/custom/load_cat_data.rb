INE::Places.preload

ID = '9'

INE::Places::AutonomousRegionsCollection.class_eval do
  @records.delete_if { |r| r.id != ID }
end

INE::Places::ProvincesCollection.class_eval do
  @records.delete_if { |r| r.autonomous_region_id != ID }
end

INE::Places::PlacesCollection.class_eval do
  @records.delete_if { |r| r.province.autonomous_region_id != ID }
end

# Scope places

GobiertoBudgets::SearchEngineConfiguration::Scopes.set_places_scope(INE::Places::Place.all)

# Overwrite Catalunya

a = INE::Places::AutonomousRegionsCollection.records.detect{|r| r.name == 'Cataluña' }
a.name = 'Catalunya'
