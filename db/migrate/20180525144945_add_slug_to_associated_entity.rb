# frozen_string_literal: true

class AddSlugToAssociatedEntity < ActiveRecord::Migration[5.1]

  def change
    add_column :gobierto_budgets_associated_entities, :slug, :string, null: true
  end

end
