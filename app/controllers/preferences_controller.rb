class PreferencesController < ApplicationController
  def index
    @preferences = Current.user.preferences.recent
  end

  def destroy
    preference = Current.user.preferences.find(params[:id])
    preference.destroy!
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("preference_#{params[:id]}") }
      format.html { redirect_to preferences_path }
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
end
