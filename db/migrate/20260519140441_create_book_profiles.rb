class CreateBookProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :book_profiles do |t|
      t.references :book, null: false, foreign_key: true, index: {unique: true}
      t.float :pace
      t.float :emotional_weight
      t.float :character_depth
      t.float :world_building
      t.float :prose_complexity
      t.float :plot_intricacy
      t.float :darkness

      t.timestamps
    end
  end
end
