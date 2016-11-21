class CreateGobifyParticipationConsultationOptions < ActiveRecord::Migration
  def change
    create_table :gobierto_participation_consultation_options do |t|
      t.references :consultation, null: false
      t.string :option
      t.integer :position, null: :false
      t.timestamps null: false
      t.references :site, null: false
    end

    add_index :gobierto_participation_consultation_options, :consultation_id, name: 'gp_consultation_options_consultation_id'
    add_foreign_key :gobierto_participation_consultation_options, :gobierto_participation_consultations, column: :consultation_id, name: 'fk_gp_consultation_options_on_consultation_id'
  end
end
