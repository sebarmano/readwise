require "test_helper"

class BookTest < ActiveSupport::TestCase
  test "profiled? returns false when no profile exists" do
    assert_not books(:meh_book).profiled?
  end

  test "profiled? returns true when a profile exists" do
    assert books(:beloved).profiled?
  end

  test "book_profile returns the associated profile" do
    profile = books(:beloved).book_profile
    assert_instance_of BookProfile, profile
    assert_equal books(:beloved), profile.book
  end
end
