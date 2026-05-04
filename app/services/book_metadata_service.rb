require "net/http"
require "json"

class BookMetadataService
  CACHE_TTL = 30.days
  SEARCH_URL = "https://openlibrary.org/search.json"
  OL_BASE = "https://openlibrary.org"

  SEARCH_FIELDS = "key,ratings_average,ratings_count,subject,number_of_pages_median,cover_i"

  NOISE_SUBJECT = /\A(fiction|literature|works?|books?|stories|series|juvenile|general|nyt:|reading level|large type|new york times)/i

  Result = Data.define(:description, :average_rating, :ratings_count, :categories,
    :page_count, :thumbnail_url)

  def initialize(title, author)
    @title = title.to_s
    @author = author.to_s
  end

  def call
    Rails.cache.fetch("book_meta_v2:#{@title}:#{@author}", expires_in: CACHE_TTL) do
      fetch
    end
  end

  private

  def fetch
    doc = search_doc
    return nil unless doc

    Result.new(
      description: fetch_description(doc["key"]),
      average_rating: doc["ratings_average"]&.round(1),
      ratings_count: doc["ratings_count"],
      categories: clean_subjects(doc["subject"]),
      page_count: doc["number_of_pages_median"],
      thumbnail_url: cover_url(doc["cover_i"])
    )
  rescue
    nil
  end

  def search_doc
    uri = URI(SEARCH_URL)
    uri.query = URI.encode_www_form(title: @title, author: @author, limit: 1, fields: SEARCH_FIELDS)
    res = Net::HTTP.get_response(uri)
    return nil unless res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body).dig("docs", 0)
  rescue
    nil
  end

  def fetch_description(work_key)
    return nil unless work_key
    uri = URI("#{OL_BASE}#{work_key}.json")
    res = Net::HTTP.get_response(uri)
    return nil unless res.is_a?(Net::HTTPSuccess)
    raw = JSON.parse(res.body)["description"]
    raw.is_a?(Hash) ? raw["value"] : raw.to_s.presence
  rescue
    nil
  end

  def cover_url(cover_id)
    "https://covers.openlibrary.org/b/id/#{cover_id}-L.jpg" if cover_id
  end

  def clean_subjects(subjects)
    return [] unless subjects
    subjects
      .select { |s| s.length.between?(5, 28) && s.match?(/\A[A-Z][a-z][\w\s&'-]{3,}\z/) }
      .reject { |s| s.match?(NOISE_SUBJECT) }
      .first(3)
  end
end
