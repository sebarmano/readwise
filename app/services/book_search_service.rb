require "net/http"
require "json"

class BookSearchService
  BASE_URL = "https://openlibrary.org/search.json"

  def self.search(title, http: Net::HTTP)
    new(http:).search(title)
  end

  def initialize(http: Net::HTTP)
    @http = http
  end

  def search(title)
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(title: title, limit: 5)
    response = @http.get_response(uri)
    parse(JSON.parse(response.body))
  rescue
    []
  end

  private

  def parse(data)
    (data["docs"] || []).map do |doc|
      {
        title: doc["title"],
        author: Array(doc["author_name"]).first,
        year: doc["first_publish_year"],
        genre: Array(doc["subject"]).first
      }
    end
  end
end
