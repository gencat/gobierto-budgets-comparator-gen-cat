SEED_FILE_PATH = "#{Rails.root}/db/seeds/associated_entities.yml"
entities_attributes = YAML.load_file(SEED_FILE_PATH)

entities_attributes.each do |entity_attributes|
  ::GobiertoBudgets::AssociatedEntity.create(entity_attributes)
end
