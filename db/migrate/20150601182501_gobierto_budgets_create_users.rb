class GobiertoBudgetsCreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :password_digest
      t.string :remember_digest
      t.string :password_reset_token
      t.integer :place_id
      t.string :document_type
      t.string :document_number, unique: true

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :place_id
  end
end
