class LlmController < ApplicationController
  include ActionController::Live

  def recommend
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    RecommendationService.new(Current.user, clarification: params[:clarification].presence).call do |chunk|
      response.stream.write("data: #{chunk}\n\n")
    end
    response.stream.write("data: [DONE]\n\n")
  rescue OllamaClient::ConnectionError => e
    response.stream.write("data: [ERROR] #{e.message}\n\n")
  rescue => e
    response.stream.write("data: [ERROR] #{e.message}\n\n")
  ensure
    response.stream.close
  end

  private

  def request_authentication
    head :unauthorized
  end
end
