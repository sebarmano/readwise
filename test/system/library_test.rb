require "application_system_test_case"

class LibraryTest < ApplicationSystemTestCase
  setup do
    @user = create_user
    @beloved = Book.create!(user: @user, title: "Beloved", author: "Toni Morrison",
      year: 1987, genre: "Fiction", rating: :loved)
    @meh_book = Book.create!(user: @user, title: "The Alchemist", author: "Paulo Coelho",
      year: 1988, genre: "Fiction", rating: :meh)
    sign_in_as @user
  end

  test "user sees their books on the library page" do
    visit books_path

    assert_text @beloved.title
    assert_text @beloved.author
  end

  test "user can filter books by rating" do
    visit books_path
    click_on "Loved"

    assert_text @beloved.title
    assert_no_text @meh_book.title
  end

  test "user can search books by title" do
    visit books_path
    find_field("Search").fill_in with: "Beloved"
    find_field("Search").send_keys :return

    assert_text @beloved.title
    assert_no_text @meh_book.title
  end

  test "user can add a book to their library" do
    visit new_book_path
    fill_in "Title", with: "Station Eleven"
    fill_in "Author", with: "Emily St. John Mandel"
    fill_in "Year", with: "2014"
    fill_in "Genre", with: "Fiction"
    choose "Loved"
    click_on "Save book"

    assert_text "Station Eleven"
    assert_text "Emily St. John Mandel"
  end

  test "user can edit a book" do
    visit edit_book_path(@beloved)
    fill_in "Notes", with: "A masterpiece"
    click_on "Save book"

    assert_text "A masterpiece"
  end

  test "user can delete a book" do
    visit books_path
    assert_text @beloved.title

    visit book_path(@beloved)
    accept_confirm { click_on "Delete book" }

    assert_no_text @beloved.title
  end
end
