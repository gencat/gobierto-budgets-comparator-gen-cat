class CreateGobifyParticipationConsultations < ActiveRecord::Migration
  def change
    create_table :gobierto_participation_consultations do |t|
      t.references :user, null: false
      t.string :title
      t.text :body
      t.string :slug, uniq: true
      t.integer :kind, null: false
      t.datetime :open_until
      t.references :site, null: false

      t.timestamps null: false
    end

    add_index :gobierto_participation_consultations, :user_id
    add_foreign_key :gobierto_participation_consultations, :users, column: :user_id

  end
end
