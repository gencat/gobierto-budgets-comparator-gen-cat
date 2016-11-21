class CreateGobifyParticipationConsultationAnswers < ActiveRecord::Migration
  def change
    create_table :gobierto_participation_consultation_answers do |t|
      t.references :consultation, null: false
      t.string :answer
      t.text :comment
      t.references :user, null: false
      t.references :consultation_option
      t.timestamps null: false
      t.references :site, null: false
    end

    add_index :gobierto_participation_consultation_answers, :consultation_id, name: 'gp_consultation_answers_consultation_id'
    add_index :gobierto_participation_consultation_answers, :user_id, name: 'gp_consultation_answers_user_id'
    add_index :gobierto_participation_consultation_answers, [:consultation_id, :user_id], unique: true, name: 'gp_consultation_answers_unique_consultation_user'

    add_foreign_key :gobierto_participation_consultation_answers, :gobierto_participation_consultations, column: :consultation_id, name: 'fk_gp_consultation_answers_consultation_id'
    add_foreign_key :gobierto_participation_consultation_answers, :users, column: :user_id, name: 'fk_gp_consultation_answers_user_id'
    add_foreign_key :gobierto_participation_consultation_answers, :gobierto_participation_consultation_options, column: :consultation_option_id, name: 'fk_gp_consultation_answers_consultation_option_id'
  end
end
