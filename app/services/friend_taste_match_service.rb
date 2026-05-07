class FriendTasteMatchService
  RATING_SCORE = {loved: 1.0, liked: 0.5, meh: 0.0}.freeze

  def self.call(user:, friend:)
    return nil unless user.full? && friend.full?

    shared = shared_titles(user, friend)
    return nil if shared.empty?

    score = shared.sum do |title|
      user_rating = book_score(user, title)
      friend_rating = book_score(friend, title)
      1.0 - (user_rating - friend_rating).abs
    end / shared.size

    rounded = score.round(4)
    update_friendship(user, friend, rounded)
    rounded
  end

  def self.shared_titles(user, friend)
    user_titles = user.books.pluck(:title).map(&:downcase).to_set
    friend.books.pluck(:title).map(&:downcase).select { |t| user_titles.include?(t) }
  end
  private_class_method :shared_titles

  def self.book_score(user, title)
    book = user.books.find_by("LOWER(title) = ?", title)
    RATING_SCORE.fetch(book&.rating&.to_sym, 0.5)
  end
  private_class_method :book_score

  def self.update_friendship(user, friend, score)
    friendship = Friendship.where(user: user, friend: friend)
      .or(Friendship.where(user: friend, friend: user))
      .accepted.first
    friendship&.update_columns(match_score: score)
  end
  private_class_method :update_friendship
end
