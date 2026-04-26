class AddTasteMatchToRecommenders < ActiveRecord::Migration[8.1]
  def change
    add_column :recommenders, :fiction_match, :float
    add_column :recommenders, :nonfiction_match, :float
  end
end
