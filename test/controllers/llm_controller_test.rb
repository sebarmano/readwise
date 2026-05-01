require "test_helper"

class LlmControllerTest < ActionDispatch::IntegrationTest
  def with_fake_service(chunks: ["token"], raise_error: nil)
    error = raise_error
    fake = Object.new
    fake.define_singleton_method(:call) do |&blk|
      raise error if error
      chunks.each { |c| blk&.call(c) }
    end
    RecommendationService.define_singleton_method(:new) { |*| fake }
    yield
  ensure
    RecommendationService.singleton_class.remove_method(:new)
  end

  test "requires authentication" do
    get llm_recommend_path
    assert_response :unauthorized
  end

  test "returns SSE content type" do
    sign_in_as users(:one)
    with_fake_service { get llm_recommend_path }
    assert_equal "text/event-stream", response.media_type
  end

  test "streams token chunks as SSE events" do
    sign_in_as users(:one)
    with_fake_service(chunks: ["Hello", " world"]) { get llm_recommend_path }
    assert_includes response.body, "data: Hello"
    assert_includes response.body, "data:  world"
  end

  test "streams DONE event at end" do
    sign_in_as users(:one)
    with_fake_service { get llm_recommend_path }
    assert_includes response.body, "data: [DONE]"
  end

  test "passes clarification param to service" do
    received = nil
    fake = Object.new
    fake.define_singleton_method(:call) { |&blk| }
    RecommendationService.define_singleton_method(:new) do |_user, clarification: nil, **|
      received = clarification
      fake
    end
    sign_in_as users(:one)
    get llm_recommend_path, params: {clarification: "something dark"}
    assert_equal "something dark", received
  ensure
    RecommendationService.singleton_class.remove_method(:new)
  end

  test "streams ERROR event when ollama unreachable" do
    sign_in_as users(:one)
    with_fake_service(raise_error: OllamaClient::ConnectionError) { get llm_recommend_path }
    assert_includes response.body, "data: [ERROR] Could not connect to Ollama"
  end
end
