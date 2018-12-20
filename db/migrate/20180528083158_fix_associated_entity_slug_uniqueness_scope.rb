# frozen_string_literal: true

class FixAssociatedEntitySlugUniquenessScope < ActiveRecord::Migration[5.1]

  def change
    remove_index :gobierto_budgets_associated_entities, name: :index_associated_entities_on_slug_and_ine_code
    add_index :gobierto_budgets_associated_entities, :slug, unique: true
  end

end
