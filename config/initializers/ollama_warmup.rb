if Rails.env.production?
  Rails.application.config.after_initialize do
    OllamaWarmupJob.perform_later
  end
end
