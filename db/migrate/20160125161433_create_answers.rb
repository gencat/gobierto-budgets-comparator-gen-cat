class CreateAnswers < ActiveRecord::Migration[4.2]
  def change
    create_table :answers do |t|
      t.references :user
      t.string :temporary_user_id
      t.string :answer_text
      t.integer :question_id
      t.timestamps null: false
    end
  end
end
