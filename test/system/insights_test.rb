require "application_system_test_case"

class InsightsTest < ApplicationSystemTestCase
  setup do
    @user = create_user
    Book.create!(user: @user, title: "Beloved", author: "Toni Morrison",
      year: 1987, genre: "Fiction", rating: :loved, mood: "literary/emotional", pace: "slow")
    Book.create!(user: @user, title: "Sapiens", author: "Yuval Noah Harari",
      year: 2011, genre: "Non-Fiction", rating: :loved, mood: "educational/inspiring", pace: "medium")
    Book.create!(user: @user, title: "The Alchemist", author: "Paulo Coelho",
      year: 1988, genre: "Fiction", rating: :meh, mood: "spiritual", pace: "fast")
    sign_in_as @user
  end

  test "insights page renders total books count" do
    visit insights_path
    assert_selector ".big-num", text: "3"
  end

  test "insights page renders genre chart canvas" do
    visit insights_path
    assert_selector "canvas#genre-chart"
  end

  test "mood cloud renders top moods" do
    visit insights_path
    assert_selector ".mood-cloud-tag"
  end

  test "author list renders authors" do
    visit insights_path
    assert_selector ".author-row"
    assert_text "Toni Morrison"
  end

  test "ratings bars are present" do
    visit insights_path
    assert_selector ".bar-row__fill--loved"
    assert_selector ".bar-row__fill--meh"
  end

  test "insights page is protected" do
    using_session("guest") do
      visit insights_path
      assert_current_path new_session_path
    end
  end
end
