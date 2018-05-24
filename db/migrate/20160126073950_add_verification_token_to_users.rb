class AddVerificationTokenToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :verification_token, :string
  end
end
