require "net/http"

class BookCoversController < ApplicationController
  CACHE_TTL = 30.days
  BASE_URL = "https://covers.openlibrary.org/b/title"

  def show
    result = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { fetch_cover }

    if result
      expires_in 30.days, public: false
      send_data result[:data], type: result[:type], disposition: "inline"
    else
      head :not_found
    end
  end

  private

  def cache_key = "book_cover:#{params[:title]}:#{size}"
  def size = params[:size].in?(%w[S M L]) ? params[:size] : "M"

  def fetch_cover
    uri = URI("#{BASE_URL}/#{ERB::Util.url_encode(params[:title].to_s)}-#{size}.jpg")
    res = follow_redirects(uri)
    return nil unless res.is_a?(Net::HTTPSuccess) && res.body.bytesize > 1_000

    {data: res.body, type: res["Content-Type"].presence || "image/jpeg"}
  rescue
    nil
  end

  def follow_redirects(uri, limit = 5)
    return Net::HTTPResponse.new("1.1", "508", "Too many redirects") if limit.zero?
    res = Net::HTTP.get_response(uri)
    res.is_a?(Net::HTTPRedirection) ? follow_redirects(URI(res["location"]), limit - 1) : res
  end
end
