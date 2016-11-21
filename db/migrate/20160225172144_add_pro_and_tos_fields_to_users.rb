class AddProAndTosFieldsToUsers < ActiveRecord::Migration
  def up
    add_column :users, :pro, :boolean, default: false
    add_column :users, :terms_of_service, :boolean, default: false
    User.update_all(pro: false, terms_of_service: true)
  end
  def down
    remove_column :users, :pro
    remove_column :users, :terms_of_service
  end
end
