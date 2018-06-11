class AddBudgetLineAttributesToAnswers < ActiveRecord::Migration[4.2]
  def change
    add_column :answers, :place_id, :integer, index: true
    add_column :answers, :kind, :string, index: true
    add_column :answers, :year, :integer, index: true
    add_column :answers, :area_name, :string, index: true
    add_column :answers, :code, :string, index: true
  end

end
