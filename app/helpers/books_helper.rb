module BooksHelper
  def rating_chip_class(rating)
    active = params[:rating] == rating.to_s || (rating.nil? && params[:rating].blank?)
    ["chip", rating&.to_s, ("active" if active)].compact.join(" ")
  end

  def genre_chip_class(genre)
    ["chip", ("active" if params[:genre] == genre)].compact.join(" ")
  end
end
