class CreateGobifyCmsPages < ActiveRecord::Migration[4.2]
  def change
    create_table :gobierto_cms_pages do |t|
      t.string :title
      t.string :slug, index: true, unique: true
      t.text :body
      t.integer :attachments_count, default: 0
      t.integer :parent_id, index: true
      t.integer :position, index: true
      t.datetime :deleted_at, index: true

      t.timestamps null: false
      t.references :site, null: false
    end
  end
end
