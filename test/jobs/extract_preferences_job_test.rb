require "test_helper"

class ExtractPreferencesJobTest < ActiveJob::TestCase
  def stub_service_call(returns: [])
    fake = Object.new
    fake.define_singleton_method(:call) { returns }
    PreferenceExtractionService.define_singleton_method(:new) { |*| fake }
    yield
  ensure
    PreferenceExtractionService.singleton_class.remove_method(:new)
  end

  test "performs extraction for the given user" do
    called = false
    fake = Object.new
    fake.define_singleton_method(:call) {
      called = true
      []
    }
    PreferenceExtractionService.define_singleton_method(:new) { |*| fake }

    ExtractPreferencesJob.perform_now(users(:one).id, [], "recommendation_chat")
    assert called
  ensure
    PreferenceExtractionService.singleton_class.remove_method(:new)
  end

  test "passes messages and source to PreferenceExtractionService" do
    received = {}
    fake = Object.new
    fake.define_singleton_method(:call) { [] }
    PreferenceExtractionService.define_singleton_method(:new) do |user, messages:, source:|
      received = {user: user, messages: messages, source: source}
      fake
    end

    messages = [{role: "user", content: "I like mysteries"}]
    ExtractPreferencesJob.perform_now(users(:one).id, messages, "book_chat")

    assert_equal users(:one), received[:user]
    assert_equal messages, received[:messages]
    assert_equal "book_chat", received[:source]
  ensure
    PreferenceExtractionService.singleton_class.remove_method(:new)
  end

  test "is discarded when user is not found" do
    stub_service_call do
      assert_nothing_raised do
        ExtractPreferencesJob.perform_now(999_999, [], "recommendation_chat")
      end
    end
  end
end
