class AddDeletedAtToGobifyParticipationConsultationOption < ActiveRecord::Migration
  def change
    add_column :gobierto_participation_consultation_options, :deleted_at, :datetime
    add_index :gobierto_participation_consultation_options, :deleted_at
  end
end
