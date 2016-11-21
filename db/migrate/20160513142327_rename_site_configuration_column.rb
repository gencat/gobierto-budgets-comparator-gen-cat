class RenameSiteConfigurationColumn < ActiveRecord::Migration
  def change
    rename_column :sites, :configuration, :configuration_data
  end
end
