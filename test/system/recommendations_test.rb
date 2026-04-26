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

  test "clicking Start reading updates card status pill inline" do
    Recommendation.create!(user: @user, recommender: @friend,
      book_title: "Dune", book_author: "Frank Herbert", status: :pending)

    visit recommendations_path
    click_button "Start reading"

    assert_selector ".status-pill.reading"
    assert_no_selector ".status-pill.pending"
    assert_current_path recommendations_path
  end

  test "clicking Mark as read shows outcome rating form" do
    Recommendation.create!(user: @user, recommender: @friend,
      book_title: "Dune", book_author: "Frank Herbert", status: :reading)

    visit recommendations_path
    click_button "Mark as read"

    assert_selector ".outcome-form"
    assert_button "Loved"
    assert_button "Liked"
    assert_button "Meh"
  end

  test "selecting an outcome rating updates card with outcome pill" do
    Recommendation.create!(user: @user, recommender: @friend,
      book_title: "Dune", book_author: "Frank Herbert", status: :reading)

    visit recommendations_path
    click_button "Mark as read"
    click_button "Loved"

    assert_selector ".outcome-pill.loved"
    assert_no_selector ".outcome-form"
  end

  test "clicking Skip moves card to skipped status" do
    Recommendation.create!(user: @user, recommender: @friend,
      book_title: "Dune", book_author: "Frank Herbert", status: :pending)

    visit recommendations_path
    click_button "Skip"

    assert_selector ".status-pill.skipped"
    assert_no_selector ".rec-card__actions"
  end
end
