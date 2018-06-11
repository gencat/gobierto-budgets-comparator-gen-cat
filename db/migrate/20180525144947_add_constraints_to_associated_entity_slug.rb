# frozen_string_literal: true

class AddConstraintsToAssociatedEntitySlug < ActiveRecord::Migration[5.1]

  def change
    change_column :gobierto_budgets_associated_entities, :slug, :string, null: false
    add_index :gobierto_budgets_associated_entities, [:slug, :ine_code], unique: true, name: :index_associated_entities_on_slug_and_ine_code
  end

end
