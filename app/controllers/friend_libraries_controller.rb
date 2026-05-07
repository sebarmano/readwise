class FriendLibrariesController < ApplicationController
  def show
    @friend = User.find(params[:user_id])
    unless Current.user.friends.include?(@friend)
      return head :forbidden
    end

    @visibility = @friend.library_visibility
    @now_reading = @friend.books.where(rating: nil).order(updated_at: :desc) if show_current_book?
    @books = @friend.books.order(read_at: :desc) if @visibility == "full"
  end

  private

  def show_current_book?
    %w[full current_book].include?(@visibility)
  end
end
