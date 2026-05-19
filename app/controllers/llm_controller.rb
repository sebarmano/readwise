class LlmController < ApplicationController
  include ActionController::Live

  def question
    sse_stream do
      QuestionService.new(
        Current.user,
        clarification: params[:clarification].presence,
        messages: parsed_messages
      ).call do |chunk|
        response.stream.write("data: #{chunk}\n\n")
      end
    end
  end

  def recommend
    messages = parsed_messages
    sse_stream do
      RecommendationService.new(
        Current.user,
        clarification: params[:clarification].presence,
        messages: messages
      ).call
      ExtractPreferencesJob.perform_later(Current.user.id, messages, "recommendation_chat")
    end
  end

  def book_chat
    sse_stream do
      BookChatService.new(
        title: params[:title].to_s,
        author: params[:author].to_s,
        messages: parsed_messages
      ).call do |chunk|
        response.stream.write("data: #{chunk}\n\n")
      end
    end
  end

  private

  def parsed_messages
    return [] unless params[:messages].present?
    JSON.parse(params[:messages])
      .map { |m| m.slice("role", "content").transform_keys(&:to_sym) }
  rescue JSON::ParserError
    []
  end

  def sse_stream
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"
    yield
    response.stream.write("data: [DONE]\n\n")
  rescue LlmClient::ConnectionError => e
    response.stream.write("data: [ERROR] #{e.message}\n\n")
  rescue => e
    response.stream.write("data: [ERROR] #{e.message}\n\n")
  ensure
    response.stream.close
  end

  def request_authentication
    head :unauthorized
  end
end
