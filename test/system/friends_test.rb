require "application_system_test_case"

class FriendsTest < ApplicationSystemTestCase
  setup do
    @user = create_user
    sign_in_as @user
  end

  test "shows empty state when user has no friends" do
    visit recommenders_path
    assert_text "No friends added yet"
  end

  test "friend card shows name and match bars when scores exist" do
    Recommender.create!(
      user: @user, name: "Marco",
      recommender_type: :friend,
      fiction_match: 0.87, nonfiction_match: 0.45
    )

    visit recommenders_path

    within(".friend-card", text: "Marco") do
      assert_selector ".match-bar__fill"
    end
  end

  test "friend card shows dash placeholder when scores are nil" do
    Recommender.create!(user: @user, name: "Alex", recommender_type: :friend)

    visit recommenders_path

    within(".friend-card", text: "Alex") do
      assert_text "—"
    end
  end

  test "friend card shows rec counts" do
    friend = Recommender.create!(user: @user, name: "Lea", recommender_type: :friend)
    Recommendation.create!(user: @user, recommender: friend,
      book_title: "Piranesi", book_author: "Clarke", status: :pending)
    Recommendation.create!(user: @user, recommender: friend,
      book_title: "Dune", book_author: "Herbert", status: :read, outcome_rating: :loved)

    visit recommenders_path

    within(".friend-card", text: "Lea") do
      assert_text "2 recs"
      assert_text "1 read"
      assert_text "1 pending"
    end
  end

  test "green bar for scores at or above 75 percent" do
    Recommender.create!(user: @user, name: "Sam", recommender_type: :friend,
      fiction_match: 0.8)

    visit recommenders_path

    assert_selector ".match-bar__fill--green"
  end

  test "amber bar for scores between 50 and 75 percent" do
    Recommender.create!(user: @user, name: "Kim", recommender_type: :friend,
      fiction_match: 0.6)

    visit recommenders_path

    assert_selector ".match-bar__fill--amber"
  end

  test "red bar for scores below 50 percent" do
    Recommender.create!(user: @user, name: "Pat", recommender_type: :friend,
      fiction_match: 0.3)

    visit recommenders_path

    assert_selector ".match-bar__fill--red"
  end

  test "claude recommenders do not appear on friends page" do
    Recommender.create!(user: @user, name: "ReadWise AI", recommender_type: :claude)

    visit recommenders_path

    assert_no_text "ReadWise AI"
  end
end
