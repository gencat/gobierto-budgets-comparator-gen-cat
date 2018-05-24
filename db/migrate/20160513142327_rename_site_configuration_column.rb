class RenameSiteConfigurationColumn < ActiveRecord::Migration[4.2]
  def change
    rename_column :sites, :configuration, :configuration_data
  end
end
