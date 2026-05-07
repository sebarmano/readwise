require "test_helper"

class UserPreferenceTest < ActiveSupport::TestCase
  # Validations
  test "valid with signal, source, and user" do
    pref = UserPreference.new(signal: "prefers slow-burn pacing", source: "recommendation_chat", user: users(:one))
    assert pref.valid?
  end

  test "invalid without signal" do
    pref = UserPreference.new(source: "recommendation_chat", user: users(:one))
    assert_not pref.valid?
    assert_includes pref.errors[:signal], "can't be blank"
  end

  test "invalid without source" do
    pref = UserPreference.new(signal: "avoids heavy violence", user: users(:one))
    assert_not pref.valid?
    assert_includes pref.errors[:source], "can't be blank"
  end

  test "invalid without user" do
    pref = UserPreference.new(signal: "avoids heavy violence", source: "book_chat")
    assert_not pref.valid?
  end

  # Scopes
  test "recent returns preferences ordered by created_at desc" do
    ordered = UserPreference.where(user: users(:one)).recent.pluck(:signal)
    assert_equal "interested in unreliable narrators", ordered.first
    assert_equal "prefers slow-burn pacing", ordered.last
  end

  test "for_context returns at most 15 records" do
    assert UserPreference.for_context.count <= 15
  end

  test "for_context returns most recent first" do
    first = UserPreference.for_context.first
    assert_equal "interested in unreliable narrators", first.signal
  end

  # Associations
  test "belongs to user" do
    pref = user_preferences(:slow_burn)
    assert_equal users(:one), pref.user
  end
end
