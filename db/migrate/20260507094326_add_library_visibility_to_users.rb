class AddLibraryVisibilityToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :library_visibility, :integer, null: false, default: 0
  end
end
