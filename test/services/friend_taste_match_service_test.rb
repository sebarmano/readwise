require "test_helper"

class FriendTasteMatchServiceTest < ActiveSupport::TestCase
  # Both users have full visibility and overlapping books in fixtures.
  # users(:one) has beloved(loved), 1984(loved), dune(loved), sapiens(loved), etc.
  # users(:two) has other_users_book (whatever rating)

  test "returns nil when either user is not full visibility" do
    users(:two).update!(library_visibility: :current_book)
    score = FriendTasteMatchService.call(user: users(:one), friend: users(:two))
    assert_nil score
  end

  test "returns nil when friend is not full visibility" do
    users(:one).update!(library_visibility: :full)
    users(:two).update!(library_visibility: :hidden)
    score = FriendTasteMatchService.call(user: users(:one), friend: users(:two))
    assert_nil score
  end

  test "returns a float between 0 and 1 when both users have full visibility and shared books" do
    users(:one).update!(library_visibility: :full)
    users(:two).update!(library_visibility: :full)
    # Give user two a book also in user one's library
    users(:two).books.create!(title: "Beloved", author: "Toni Morrison", rating: :loved, genre: "Fiction", pace: "slow", mood: "literary")
    score = FriendTasteMatchService.call(user: users(:one), friend: users(:two))
    assert_not_nil score
    assert score.between?(0.0, 1.0)
  end

  test "returns nil when there are no shared books" do
    users(:one).update!(library_visibility: :full)
    users(:two).update!(library_visibility: :full)
    score = FriendTasteMatchService.call(user: users(:one), friend: users(:two))
    assert_nil score
  end

  test "score is symmetric — same result regardless of argument order" do
    users(:one).update!(library_visibility: :full)
    users(:two).update!(library_visibility: :full)
    users(:two).books.create!(title: "Beloved", author: "Toni Morrison", rating: :loved, genre: "Fiction", pace: "slow", mood: "literary")
    score_ab = FriendTasteMatchService.call(user: users(:one), friend: users(:two))
    score_ba = FriendTasteMatchService.call(user: users(:two), friend: users(:one))
    assert_equal score_ab, score_ba
  end

  test "stores the score on the friendship" do
    users(:one).update!(library_visibility: :full)
    users(:two).update!(library_visibility: :full)
    users(:two).books.create!(title: "Beloved", author: "Toni Morrison", rating: :loved, genre: "Fiction", pace: "slow", mood: "literary")
    FriendTasteMatchService.call(user: users(:one), friend: users(:two))
    friendship = friendships(:one_two).reload
    assert_not_nil friendship.match_score
  end
end
