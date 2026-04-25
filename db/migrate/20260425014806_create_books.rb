class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :author
      t.integer :year
      t.string :genre
      t.integer :rating
      t.text :notes
      t.string :cover_url
      t.date :read_at

      t.timestamps
    end
  end
end
