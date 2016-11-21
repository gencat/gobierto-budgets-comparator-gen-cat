class CreateGobifyParticipationComments < ActiveRecord::Migration
  def change
    create_table :gobierto_participation_comments do |t|
      t.references :user, null: false
      t.text :body
      t.integer :commentable_id, null: false
      t.string :commentable_type, null: false
      t.references :site, null: false
      t.timestamps null: false
    end

    add_index :gobierto_participation_comments, :user_id
    add_index :gobierto_participation_comments, :created_at
    add_index :gobierto_participation_comments, :commentable_id
    add_index :gobierto_participation_comments, :commentable_type

    add_foreign_key :gobierto_participation_comments, :users, column: :user_id
  end
end
