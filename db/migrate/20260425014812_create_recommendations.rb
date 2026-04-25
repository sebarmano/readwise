class CreateRecommendations < ActiveRecord::Migration[8.1]
  def change
    create_table :recommendations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :recommender, null: false, foreign_key: true
      t.string :book_title
      t.string :book_author
      t.text :reason
      t.integer :status
      t.date :read_at

      t.timestamps
    end
  end
end
