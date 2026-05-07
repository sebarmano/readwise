require "test_helper"

class FriendshipsMatchScoreTest < ActionDispatch::IntegrationTest
  test "shows match score label when friendship has a score" do
    friendships(:one_two).update!(match_score: 0.85)
    sign_in_as users(:one)
    get friendships_path
    assert_includes response.body, "Great match"
  end

  test "shows nil state when friendship has no score" do
    friendships(:one_two).update!(match_score: nil)
    sign_in_as users(:one)
    get friendships_path
    assert_includes response.body, "Not enough shared reads"
  end

  test "shows 'Good match' label for mid-range score" do
    friendships(:one_two).update!(match_score: 0.65)
    sign_in_as users(:one)
    get friendships_path
    assert_includes response.body, "Good match"
  end

  test "shows 'Different tastes' label for low score" do
    friendships(:one_two).update!(match_score: 0.3)
    sign_in_as users(:one)
    get friendships_path
    assert_includes response.body, "Different tastes"
  end
end
