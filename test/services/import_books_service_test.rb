require "test_helper"

class ImportBooksServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "import@test.com", password: "password")
  end

  test "imports valid rows and skips duplicates" do
    csv = "title,author,rating\nDune,Herbert,loved\nDune,Herbert,loved"
    result = ImportBooksService.new(StringIO.new(csv), @user).call
    assert_equal 1, result[:imported]
    assert_equal 1, result[:skipped]
    assert_empty result[:errors]
  end

  test "reports invalid rating in errors" do
    csv = "title,author,rating\nBad Book,Author,amazing"
    result = ImportBooksService.new(StringIO.new(csv), @user).call
    assert_equal 0, result[:imported]
    assert result[:errors].any? { |e| e.include?("rating") }
  end

  test "skips rows with missing title" do
    csv = "title,author,rating\n,Author,loved"
    result = ImportBooksService.new(StringIO.new(csv), @user).call
    assert_equal 0, result[:imported]
    assert result[:errors].any?
  end

  test "duplicate check is case-insensitive" do
    @user.books.create!(title: "DUNE", author: "Herbert", rating: :loved)
    csv = "title,author,rating\ndune,Herbert,liked"
    result = ImportBooksService.new(StringIO.new(csv), @user).call
    assert_equal 0, result[:imported]
    assert_equal 1, result[:skipped]
  end
end
