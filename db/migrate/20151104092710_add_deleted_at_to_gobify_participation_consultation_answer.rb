class AddDeletedAtToGobifyParticipationConsultationAnswer < ActiveRecord::Migration[4.2]
  def change
    add_column :gobierto_participation_consultation_answers, :deleted_at, :datetime
    add_index :gobierto_participation_consultation_answers, :deleted_at
  end
end
