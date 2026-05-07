class AddMatchScoreToFriendships < ActiveRecord::Migration[8.1]
  def change
    add_column :friendships, :match_score, :float
  end
end
