require "test_helper"

class BookProfileTest < ActiveSupport::TestCase
  test "valid profile saves successfully" do
    profile = BookProfile.new(
      book: books(:sapiens),
      pace: 0.8,
      emotional_weight: 0.9,
      character_depth: 0.7,
      world_building: 0.4,
      prose_complexity: 0.6,
      plot_intricacy: 0.5,
      darkness: 0.8
    )
    assert profile.valid?
    assert profile.save
  end

  test "invalid without book" do
    profile = BookProfile.new(pace: 0.5)
    assert_not profile.valid?
    assert_includes profile.errors[:book], "must exist"
  end

  test "validates uniqueness of book" do
    existing = book_profiles(:one)
    duplicate = BookProfile.new(book: existing.book, pace: 0.5)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:book], "has already been taken"
  end

  test "all 7 dimension columns accept nil" do
    profile = BookProfile.new(book: books(:meh_book))
    assert profile.valid?
    assert_nil profile.pace
    assert_nil profile.emotional_weight
    assert_nil profile.character_depth
    assert_nil profile.world_building
    assert_nil profile.prose_complexity
    assert_nil profile.plot_intricacy
    assert_nil profile.darkness
  end

  test "pace accepts values between 0.0 and 1.0" do
    profile = BookProfile.new(book: books(:meh_book), pace: 0.0)
    assert profile.valid?
    profile.pace = 1.0
    assert profile.valid?
    profile.pace = 0.5
    assert profile.valid?
  end

  test "emotional_weight accepts values between 0.0 and 1.0" do
    profile = BookProfile.new(book: books(:meh_book), emotional_weight: 0.0)
    assert profile.valid?
    profile.emotional_weight = 1.0
    assert profile.valid?
  end

  test "character_depth accepts values between 0.0 and 1.0" do
    profile = BookProfile.new(book: books(:meh_book), character_depth: 0.0)
    assert profile.valid?
    profile.character_depth = 1.0
    assert profile.valid?
  end

  test "world_building accepts values between 0.0 and 1.0" do
    profile = BookProfile.new(book: books(:meh_book), world_building: 0.0)
    assert profile.valid?
    profile.world_building = 1.0
    assert profile.valid?
  end

  test "prose_complexity accepts values between 0.0 and 1.0" do
    profile = BookProfile.new(book: books(:meh_book), prose_complexity: 0.0)
    assert profile.valid?
    profile.prose_complexity = 1.0
    assert profile.valid?
  end

  test "plot_intricacy accepts values between 0.0 and 1.0" do
    profile = BookProfile.new(book: books(:meh_book), plot_intricacy: 0.0)
    assert profile.valid?
    profile.plot_intricacy = 1.0
    assert profile.valid?
  end

  test "darkness accepts values between 0.0 and 1.0" do
    profile = BookProfile.new(book: books(:meh_book), darkness: 0.0)
    assert profile.valid?
    profile.darkness = 1.0
    assert profile.valid?
  end
end
