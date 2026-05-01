class OllamaWarmupJob < ApplicationJob
  def perform
    build_client.ensure_model_present!
  rescue OllamaClient::ConnectionError => e
    Rails.logger.warn "OllamaWarmupJob: model warmup failed — #{e.message}"
  end

  private

  def build_client = OllamaClient.new
end
