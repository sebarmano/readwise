require "test_helper"

class PreferenceExtractionServiceTest < ActiveSupport::TestCase
  def stub_client(response:)
    client = Object.new
    client.define_singleton_method(:chat) { |**| response }
    client
  end

  def messages
    [
      {role: "user", content: "I love slow-burn psychological thrillers"},
      {role: "assistant", content: "Great, any genres you want to avoid?"},
      {role: "user", content: "No heavy violence please"}
    ]
  end

  test "returns array of created UserPreference records" do
    client = stub_client(response: "prefers slow-burn pacing\navoids heavy violence")
    service = PreferenceExtractionService.new(users(:one), messages: messages, source: "recommendation_chat", client:)
    result = service.call
    assert_kind_of Array, result
    assert result.all? { |r| r.is_a?(UserPreference) }
    assert result.all?(&:persisted?)
  end

  test "parses newline-delimited output into individual signals" do
    client = stub_client(response: "enjoys magical realism\nlikes short story collections\nprefers female authors")
    service = PreferenceExtractionService.new(users(:one), messages: messages, source: "recommendation_chat", client:)
    assert_difference -> { UserPreference.count }, 3 do
      service.call
    end
  end

  test "assigns source to each created preference" do
    client = stub_client(response: "drawn to gothic themes")
    service = PreferenceExtractionService.new(users(:one), messages: messages, source: "book_chat", client:)
    result = service.call
    assert_equal "book_chat", result.first.source
  end

  test "skips duplicate signals present verbatim in last 30 days" do
    # "avoids heavy violence" fixture was created on 2026-05-03 — within 30 days of today (2026-05-07)
    client = stub_client(response: "avoids heavy violence\nenjoys unreliable narrators")
    service = PreferenceExtractionService.new(users(:one), messages: messages, source: "recommendation_chat", client:)
    assert_difference -> { UserPreference.count }, 1 do
      service.call
    end
  end

  test "returns empty array when LLM output is blank" do
    client = stub_client(response: "")
    service = PreferenceExtractionService.new(users(:one), messages: messages, source: "recommendation_chat", client:)
    assert_equal [], service.call
  end

  test "returns empty array when LLM output is nil" do
    client = stub_client(response: nil)
    service = PreferenceExtractionService.new(users(:one), messages: messages, source: "recommendation_chat", client:)
    assert_equal [], service.call
  end

  test "strips blank lines from parsed output" do
    client = stub_client(response: "enjoys epistolary novels\n\n\nlikes books under 300 pages\n")
    service = PreferenceExtractionService.new(users(:one), messages: messages, source: "recommendation_chat", client:)
    assert_difference -> { UserPreference.count }, 2 do
      service.call
    end
  end

  test "scopes duplicate check to the current user" do
    # "prefers short novels under 300 pages" belongs to user two — should NOT block user one
    client = stub_client(response: "prefers short novels under 300 pages")
    service = PreferenceExtractionService.new(users(:one), messages: messages, source: "recommendation_chat", client:)
    assert_difference -> { UserPreference.count }, 1 do
      service.call
    end
  end
end
