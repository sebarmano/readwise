class PreferenceExtractionService
  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are extracting durable reading preference signals from a conversation.
    Return 3-6 short, third-person-free signals, one per line.
    Good: "prefers slow-burn pacing", "avoids heavy violence", "interested in unreliable narrators"
    Bad: "user said they like fantasy" (too raw), "wants a good book" (too vague)
    Output only the signals, one per line. No numbering, no bullet points, no extra text.
  PROMPT

  def initialize(user, messages:, source:, client: LlmClient.default)
    @user = user
    @messages = messages
    @source = source
    @client = client
  end

  def call
    raw = @client.chat(messages: extraction_messages)
    return [] if raw.blank?

    signals = raw.split("\n").map(&:strip).reject(&:blank?)
    signals.filter_map do |signal|
      next if duplicate?(signal)
      @user.preferences.create!(signal: signal, source: @source)
    end
  end

  private

  def extraction_messages
    [
      {role: "system", content: SYSTEM_PROMPT},
      *@messages,
      {role: "user", content: "Based on this conversation, list the reading preferences you learned about the user."}
    ]
  end

  def duplicate?(signal)
    @user.preferences
      .where(signal: signal)
      .where("created_at > ?", 30.days.ago)
      .exists?
  end
end
