class AddDeletedAtToGobifyParticipationConsultation < ActiveRecord::Migration
  def change
    add_column :gobierto_participation_consultations, :deleted_at, :datetime
    add_index :gobierto_participation_consultations, :deleted_at
  end
end
