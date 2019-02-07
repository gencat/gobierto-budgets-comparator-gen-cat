# This migration comes from gobierto_participation (originally 20151027153937)
class CreateGobifyParticipationIdeas < ActiveRecord::Migration[4.2]
  def change
    create_table :gobierto_participation_ideas do |t|
      t.references :user, null: false
      t.string :title
      t.text :body
      t.string :slug, uniq: true
      t.references :site, null: false

      t.timestamps null: false
    end

    add_index :gobierto_participation_ideas, :user_id
    add_index :gobierto_participation_ideas, :created_at
    add_foreign_key :gobierto_participation_ideas, :users, column: :user_id
  end
end
