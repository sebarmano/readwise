class AddMoodAndPaceToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :mood, :string
    add_column :books, :pace, :string
  end
end
