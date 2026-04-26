class AddOutcomeRatingAndBookTypeToRecommendations < ActiveRecord::Migration[8.1]
  def change
    add_column :recommendations, :outcome_rating, :integer
    add_column :recommendations, :book_type, :string
  end
end
