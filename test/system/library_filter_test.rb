require "application_system_test_case"

class LibraryFilterTest < ApplicationSystemTestCase
  setup do
    @user = create_user
    Book.create!(user: @user, title: "Dune", author: "Frank Herbert", genre: "Sci-Fi", rating: :loved)
    Book.create!(user: @user, title: "The Alchemist", author: "Paulo Coelho", genre: "Fiction", rating: :meh)
    sign_in_as @user
  end

  test "search filters books as user types" do
    visit books_path
    find_field("Search").fill_in with: "Dune"
    sleep 0.3
    assert_selector ".book-card", count: 1
    assert_text "Dune"
    assert_no_text "The Alchemist"
  end

  test "genre chip filters to matching books" do
    visit books_path
    click_button "Sci-Fi"
    assert_text "Dune"
    assert_no_text "The Alchemist"
  end
end
