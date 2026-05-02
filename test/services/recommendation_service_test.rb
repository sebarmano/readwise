require "test_helper"

class RecommendationServiceTest < ActiveSupport::TestCase
  def fake_ollama(json_response)
    client = Object.new
    client.define_singleton_method(:chat_stream) do |messages:, &blk|
      blk.call(json_response)
    end
    client
  end

  # --- prompt ---

  test "prompt includes reading history books" do
    service = RecommendationService.new(users(:one))
    assert_includes service.prompt, books(:beloved).title
  end

  test "prompt includes clarification when provided" do
    service = RecommendationService.new(users(:one), clarification: "something short")
    assert_includes service.prompt, "something short"
  end

  test "prompt does not include clarification section when absent" do
    service = RecommendationService.new(users(:one))
    assert_not_includes service.prompt, "clarification"
  end

  test "prompt includes past claude recommendations" do
    service = RecommendationService.new(users(:one))
    assert_includes service.prompt, recommendations(:claude_pending).book_title
  end

  test "prompt includes active friend recommendations with recommender name" do
    service = RecommendationService.new(users(:one))
    assert_includes service.prompt, recommendations(:marco_pending).book_title
    assert_includes service.prompt, recommenders(:marco).name
  end

  test "prompt only includes current user's books" do
    service = RecommendationService.new(users(:one))
    assert_not_includes service.prompt, books(:other_users_book).title
  end

  # --- call ---

  test "call persists parsed recommendations" do
    json = '[{"title":"The Left Hand of Darkness","author":"Ursula K. Le Guin","genre":"Sci-Fi","reason":"Matches your love of epic fiction"}]'
    assert_difference "Recommendation.count", 1 do
      RecommendationService.new(users(:one), ollama_client: fake_ollama(json)).call
    end
  end

  test "call links recommendation to claude recommender" do
    json = '[{"title":"The Left Hand of Darkness","author":"Ursula K. Le Guin","genre":"Sci-Fi","reason":"Matches your love of epic fiction"}]'
    RecommendationService.new(users(:one), ollama_client: fake_ollama(json)).call
    assert_equal "claude", Recommendation.last.source
  end

  test "call persists title author and reason" do
    json = '[{"title":"Neuromancer","author":"William Gibson","genre":"Sci-Fi","reason":"Cyberpunk classic"}]'
    RecommendationService.new(users(:one), ollama_client: fake_ollama(json)).call
    rec = Recommendation.last
    assert_equal "Neuromancer", rec.book_title
    assert_equal "William Gibson", rec.book_author
    assert_equal "Cyberpunk classic", rec.reason
  end

  test "call persists multiple recommendations" do
    json = '[{"title":"A","author":"B","genre":"Fiction","reason":"r1"},{"title":"C","author":"D","genre":"Fiction","reason":"r2"}]'
    assert_difference "Recommendation.count", 2 do
      RecommendationService.new(users(:one), ollama_client: fake_ollama(json)).call
    end
  end

  test "call tolerates json wrapped in markdown fences" do
    json = "```json\n[{\"title\":\"Dune\",\"author\":\"Herbert\",\"genre\":\"Sci-Fi\",\"reason\":\"Epic\"}]\n```"
    assert_difference "Recommendation.count", 1 do
      RecommendationService.new(users(:one), ollama_client: fake_ollama(json)).call
    end
  end

  test "call does not raise when ollama returns empty response" do
    assert_no_difference "Recommendation.count" do
      RecommendationService.new(users(:one), ollama_client: fake_ollama("")).call
    end
  end

  test "call does not raise when ollama returns non-json prose" do
    assert_no_difference "Recommendation.count" do
      RecommendationService.new(users(:one), ollama_client: fake_ollama("Sorry, I cannot help with that.")).call
    end
  end
end
