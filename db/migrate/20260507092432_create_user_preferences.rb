class CreateUserPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :user_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.text :signal, null: false
      t.string :source, null: false

      t.timestamps
    end

    add_index :user_preferences, [:user_id, :created_at]
  end
end
