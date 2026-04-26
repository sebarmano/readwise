require "application_system_test_case"

class RecommendationsTest < ApplicationSystemTestCase
  setup do
    @user = create_user
    @friend = Recommender.create!(user: @user, name: "Marco", recommender_type: :friend)
    sign_in_as @user
  end

  test "shows empty state when user has no recommendations" do
    visit recommendations_path

    assert_text "No recommendations yet"
  end

  test "shows recommendation title, author, reason, and source name" do
    Recommendation.create!(
      user: @user, recommender: @friend,
      book_title: "Dune", book_author: "Frank Herbert",
      reason: "A masterpiece of world-building", status: :pending
    )

    visit recommendations_path

    assert_text "Dune"
    assert_text "Frank Herbert"
    assert_text "A masterpiece of world-building"
    assert_text "Marco"
  end

  test "orders recommendations: reading → pending → read → skipped" do
    Recommendation.create!(user: @user, recommender: @friend,
      book_title: "Skipped Book", book_author: "A", status: :skipped)
    Recommendation.create!(user: @user, recommender: @friend,
      book_title: "Pending Book", book_author: "B", status: :pending)
    Recommendation.create!(user: @user, recommender: @friend,
      book_title: "Reading Book", book_author: "C", status: :reading)
    Recommendation.create!(user: @user, recommender: @friend,
      book_title: "Read Book", book_author: "D", status: :read, outcome_rating: :liked)

    visit recommendations_path

    titles = all(".rec-card__title").map(&:text)
    assert_equal ["Reading Book", "Pending Book", "Read Book", "Skipped Book"], titles
  end

  test "shows action buttons only for pending and reading recommendations" do
    Recommendation.create!(user: @user, recommender: @friend,
      book_title: "Pending Book", book_author: "A", status: :pending)
    Recommendation.create!(user: @user, recommender: @friend,
      book_title: "Reading Book", book_author: "B", status: :reading)
    Recommendation.create!(user: @user, recommender: @friend,
      book_title: "Read Book", book_author: "C", status: :read, outcome_rating: :liked)

    visit recommendations_path

    within(".rec-card", text: "Pending Book") { assert_selector ".rec-card__actions" }
    within(".rec-card", text: "Reading Book") { assert_selector ".rec-card__actions" }
    within(".rec-card", text: "Read Book") { assert_no_selector ".rec-card__actions" }
  end

  test "shows outcome rating pill on rated recommendations" do
    Recommendation.create!(
      user: @user, recommender: @friend,
      book_title: "Loved Book", book_author: "A",
      status: :read, outcome_rating: :loved
    )

    visit recommendations_path

    assert_selector ".outcome-pill.loved"
  end

  test "shows friend source icon for friend recommendations" do
    Recommendation.create!(user: @user, recommender: @friend,
      book_title: "Dune", book_author: "A", status: :pending)

    visit recommendations_path

    assert_selector ".source-dot--friend"
  end

  test "shows claude source icon for ai recommendations" do
    ai = Recommender.create!(user: @user, name: "ReadWise AI", recommender_type: :claude)
    Recommendation.create!(user: @user, recommender: ai,
      book_title: "Foundation", book_author: "Asimov", status: :pending)

    visit recommendations_path

    assert_selector ".source-dot--claude"
  end
end
