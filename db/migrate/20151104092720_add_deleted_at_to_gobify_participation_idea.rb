class AddDeletedAtToGobifyParticipationIdea < ActiveRecord::Migration
  def change
    add_column :gobierto_participation_ideas, :deleted_at, :datetime
    add_index :gobierto_participation_ideas, :deleted_at
  end
end
