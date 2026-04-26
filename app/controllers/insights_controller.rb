class InsightsController < ApplicationController
  def index
    books = Current.user.books

    @total = books.count
    @ratings = compute_ratings(books)
    @genres = books.where.not(genre: nil).group(:genre).order("count_all desc").limit(8).count
    @authors = compute_authors(books)
    @pace = books.where.not(pace: nil).group(:pace).count
    @moods = compute_moods(books)
  end

  private

  def compute_ratings(books)
    raw = books.group(:rating).count
    loved = raw["loved"] || 0
    liked = raw["liked"] || 0
    meh = raw["meh"] || 0
    {loved:, liked:, meh:, total: @total}
  end

  def compute_authors(books)
    books.where.not(author: nil)
      .select("author, COUNT(*) AS total_count, SUM(CASE WHEN rating = #{Book.ratings["loved"]} THEN 1 ELSE 0 END) AS loved_count")
      .group(:author)
      .order("total_count DESC")
      .limit(6)
  end

  def compute_moods(books)
    all_moods = books.where.not(mood: nil).pluck(:mood)
    tally = all_moods.flat_map { |m| m.split("/").map(&:strip) }.tally
    tally.sort_by { |_, c| -c }.first(12).to_h
  end
end
