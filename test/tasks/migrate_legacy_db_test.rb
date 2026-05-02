require "test_helper"

class MigrateLegacyDbTest < ActiveSupport::TestCase
  LEGACY_DB = Rails.root.join("test/fixtures/files/legacy_library.db")

  setup do
    @user = users(:one)
  end

  test "imports books from legacy db" do
    assert_difference "Book.count", 5 do
      MigrateLegacyDb.run(LEGACY_DB, @user)
    end
  end

  test "imports recommenders from legacy db" do
    assert_difference "Recommender.count", 2 do
      MigrateLegacyDb.run(LEGACY_DB, @user)
    end
  end

  test "imports recommendations from legacy db" do
    assert_difference "Recommendation.count", 3 do
      MigrateLegacyDb.run(LEGACY_DB, @user)
    end
  end

  test "is idempotent on second run" do
    MigrateLegacyDb.run(LEGACY_DB, @user)
    assert_no_difference "Book.count" do
      MigrateLegacyDb.run(LEGACY_DB, @user)
    end
  end

  test "skips recommenders already imported" do
    MigrateLegacyDb.run(LEGACY_DB, @user)
    assert_no_difference "Recommender.count" do
      MigrateLegacyDb.run(LEGACY_DB, @user)
    end
  end

  test "skips recommendations already imported" do
    MigrateLegacyDb.run(LEGACY_DB, @user)
    assert_no_difference "Recommendation.count" do
      MigrateLegacyDb.run(LEGACY_DB, @user)
    end
  end

  test "reports counts" do
    result = MigrateLegacyDb.run(LEGACY_DB, @user)
    assert_equal 5, result[:books_imported]
    assert_equal 0, result[:books_skipped]
    assert_equal 2, result[:recommenders_imported]
    assert_equal 3, result[:recommendations_imported]
  end

  test "reports skipped counts on second run" do
    MigrateLegacyDb.run(LEGACY_DB, @user)
    result = MigrateLegacyDb.run(LEGACY_DB, @user)
    assert_equal 0, result[:books_imported]
    assert_equal 5, result[:books_skipped]
  end

  test "scopes imported records to the given user" do
    other_user = users(:two)
    other_before = other_user.books.count
    assert_difference "@user.books.count", 5 do
      MigrateLegacyDb.run(LEGACY_DB, @user)
    end
    assert_equal other_before, other_user.books.count
  end

  test "maps legacy rating integers to enum values" do
    MigrateLegacyDb.run(LEGACY_DB, @user)
    book = @user.books.find_by(title: "The Pragmatic Programmer")
    assert_equal "loved", book.rating
  end
end
