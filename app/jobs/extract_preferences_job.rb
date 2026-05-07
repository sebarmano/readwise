class ExtractPreferencesJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound

  def perform(user_id, messages, source)
    user = User.find(user_id)
    PreferenceExtractionService.new(user, messages: messages, source: source).call
  end
end
