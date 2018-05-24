class CreateAssociatedEntities < ActiveRecord::Migration[5.1]

  def change
    create_table :gobierto_budgets_associated_entities do |t|
      t.string :entity_id, null: false
      t.string :name, null: false
      t.integer :ine_code, null: false
    end

    add_index :gobierto_budgets_associated_entities, [:entity_id, :ine_code], unique: true, name: :index_associated_entities_on_entity_id_and_ine_code
    add_index :gobierto_budgets_associated_entities, [:name, :ine_code], unique: true, name: :index_associated_entities_on_name_and_ine_code
  end

end
