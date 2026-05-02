require "net/http"
require "json"

class OllamaClient
  ConnectionError = Class.new(StandardError)

  CONNECTION_ERRORS = [
    Errno::ECONNREFUSED,
    Errno::ECONNRESET,
    Errno::EHOSTUNREACH,
    Errno::ETIMEDOUT,
    SocketError,
    Net::OpenTimeout,
    Net::ReadTimeout
  ].freeze

  def initialize(url: ENV["OLLAMA_URL"], model: ENV["OLLAMA_MODEL"], http: Net::HTTP)
    @base_url = URI(url || "http://localhost:11434")
    @model = model || "qwen2.5:7b"
    @http = http
  end

  def chat(messages:)
    body = {model: @model, messages: messages, stream: false}.to_json
    response = post("/api/chat", body)
    JSON.parse(response.body).dig("message", "content")
  rescue *CONNECTION_ERRORS => e
    raise ConnectionError, e.message
  end

  def chat_stream(messages:, &block)
    body = {model: @model, messages: messages, stream: true}.to_json
    post_stream("/api/chat", body) do |line|
      data = JSON.parse(line)
      block.call(data.dig("message", "content")) unless data["done"]
    end
  rescue *CONNECTION_ERRORS => e
    raise ConnectionError, e.message
  end

  def model_present?
    response = get("/api/tags")
    models = JSON.parse(response.body).fetch("models", [])
    models.any? { |m| m["name"] == @model || m["name"].start_with?("#{@model}:") }
  rescue *CONNECTION_ERRORS => e
    raise ConnectionError, e.message
  end

  def ensure_model_present!
    return if model_present?
    post("/api/pull", {name: @model, stream: false}.to_json)
  end

  private

  def connection
    http = @http.new(@base_url.host, @base_url.port)
    http.read_timeout = 300
    http.open_timeout = 10
    http
  end

  def post(path, body)
    req = Net::HTTP::Post.new(path, "Content-Type" => "application/json")
    req.body = body
    connection.start { |conn| conn.request(req) }
  end

  def get(path)
    req = Net::HTTP::Get.new(path)
    connection.start { |conn| conn.request(req) }
  end

  def post_stream(path, body, &block)
    req = Net::HTTP::Post.new(path, "Content-Type" => "application/json")
    req.body = body
    buffer = ""
    connection.start do |conn|
      conn.request(req) do |response|
        unless response.code == "200"
          error_body = +""
          response.read_body { |c| error_body << c }
          message = begin
            JSON.parse(error_body).fetch("error", "HTTP #{response.code}")
          rescue JSON::ParserError
            "HTTP #{response.code}"
          end
          raise ConnectionError, message
        end
        response.read_body do |chunk|
          buffer += chunk
          while (line = buffer.slice!(/\A[^\n]*\n/))
            block.call(line.chomp) unless line.strip.empty?
          end
        end
      end
    end
  end
end
