class FriendshipsController < ApplicationController
  def index
    @friends = Current.user.friends
    @pending_received = Current.user.received_friendships.pending.includes(:user)
    @pending_sent = Current.user.sent_friendships.pending.includes(:friend)
  end

  def create
    FriendshipService.invite(from: Current.user, email: params.dig(:friendship, :email).to_s)
    redirect_to friendships_path
  end

  def update
    friendship = find_friendship
    return head :not_found unless friendship

    FriendshipService.accept(friendship: friendship, user: Current.user)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("friendship_#{friendship.id}", partial: "friendships/friend", locals: {friendship: friendship.reload}) }
      format.html { redirect_to friendships_path }
    end
  end

  def destroy
    friendship = find_friendship
    return head :not_found unless friendship

    FriendshipService.remove(friendship: friendship, user: Current.user)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("friendship_#{params[:id]}") }
      format.html { redirect_to friendships_path }
    end
  end

  private

  def find_friendship
    Friendship.where(user: Current.user).or(Friendship.where(friend: Current.user)).find_by(id: params[:id])
  end
end
