require "test_helper"

class BookSearchServiceTest < ActiveSupport::TestCase
  FakeResponse = Struct.new(:body)

  def fake_http(body_hash)
    response = FakeResponse.new(body_hash.to_json)
    Class.new { define_singleton_method(:get_response) { |_uri| response } }
  end

  test "returns results for a known title" do
    http = fake_http("docs" => [
      {"title" => "Dune", "author_name" => ["Frank Herbert"], "first_publish_year" => 1965, "subject" => ["Science fiction"]}
    ])

    results = BookSearchService.search("Dune", http:)

    assert results.any?
    assert_includes results.first.keys, :title
    assert_equal "Dune", results.first[:title]
    assert_equal "Frank Herbert", results.first[:author]
    assert_equal 1965, results.first[:year]
  end

  test "returns empty array on network error" do
    exploding = Class.new { def self.get_response(_uri) = raise(SocketError) }
    assert_equal [], BookSearchService.search("anything", http: exploding)
  end

  test "returns empty array when docs is missing" do
    results = BookSearchService.search("nothing", http: fake_http({}))
    assert_equal [], results
  end
end
