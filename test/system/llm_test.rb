require "application_system_test_case"

class LlmTest < ApplicationSystemTestCase
  setup do
    @user = create_user
    @claude = Recommender.create!(user: @user, name: "Claude", recommender_type: :claude)
    sign_in_as @user
  end

  test "Get Recommendations button is present on queue page" do
    visit recommendations_path
    assert_selector "button", text: "Get Recommendations"
  end

  test "clarification input is present" do
    visit recommendations_path
    assert_selector "input[data-clarification]"
  end

  test "clicking Get Recommendations streams response and adds recommendations to queue" do
    json = '[{"title":"Foundation","author":"Isaac Asimov","genre":"Sci-Fi","reason":"Epic world-building"}]'
    stub_ollama(json:)

    visit recommendations_path
    click_button "Get Recommendations"

    assert_selector ".status-pill.pending", wait: 10
    assert_text "Foundation"
  ensure
    unstub_ollama
  end

  test "shows error message when Ollama is unreachable" do
    OllamaClient.define_singleton_method(:new) do |**|
      client = Object.new
      client.define_singleton_method(:chat_stream) { |messages:, &blk| raise OllamaClient::ConnectionError }
      client
    end

    visit recommendations_path
    click_button "Get Recommendations"

    assert_text "Could not connect to Ollama", wait: 5
  ensure
    unstub_ollama
  end

  private

  def stub_ollama(json:)
    client = Object.new
    client.define_singleton_method(:chat_stream) { |messages:, &blk| blk.call(json) }
    OllamaClient.define_singleton_method(:new) { |**| client }
  end

  def unstub_ollama
    OllamaClient.singleton_class.remove_method(:new)
  rescue NameError
    nil
  end
end
