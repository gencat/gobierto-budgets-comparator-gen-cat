class CreateSubscriptions < ActiveRecord::Migration[4.2]
  def change
    create_table :subscriptions do |t|
      t.references :user, index: true, null: false
      t.integer :place_id, index: true, null: false
      t.timestamps null: false
    end

    add_foreign_key :subscriptions, :users
  end
end
