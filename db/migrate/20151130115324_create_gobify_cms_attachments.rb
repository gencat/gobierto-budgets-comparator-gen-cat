class CreateGobifyCmsAttachments < ActiveRecord::Migration
  def change
    create_table :gobierto_cms_attachments do |t|
      t.string   "attachment_file_name"
      t.string   "attachment_content_type"
      t.integer  "attachment_file_size"
      t.datetime "attachment_updated_at"
      t.references :gobierto_cms_page
      t.timestamps null: false
      t.references :site, null: false
    end
  end
end
