class CreateRecommenders < ActiveRecord::Migration[8.1]
  def change
    create_table :recommenders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.integer :recommender_type
      t.string :email_address

      t.timestamps
    end
  end
end
