# frozen_string_literal: true

class GenerateSlugsForAssociatedEntities < ActiveRecord::Migration[5.1]

  def up
    ::GobiertoBudgets::AssociatedEntity.all.each(&:save!)
  end

  def down
    ::GobiertoBudgets::AssociatedEntity.update_all(slug: nil)
  end

end
