class QuestionService
  MIN_TURNS = 3
  MAX_TURNS = 10

  # Turn 0: always ask — genre/fiction/nonfiction/mood
  FIRST_TURN_PROMPT = <<~PROMPT.strip
    You are an expert reading guide with the user's complete reading history.
    Ask ONE focused question to understand what kind of book they're in the mood for RIGHT NOW.
    Cover: fiction vs non-fiction, specific genre, or current emotional need.
    Do NOT say you're ready or give recommendations yet — only ask.
    Under 25 words. No greeting. Just the question.
  PROMPT

  # Turn 1: always ask — pace, difficulty, length, era
  SECOND_TURN_PROMPT = <<~PROMPT.strip
    You are an expert reading guide. Based on the conversation so far, ask ONE more question.
    This time probe: reading pace they want (fast-paced vs slow-burn), difficulty level (easy vs challenging),
    book length (short vs epic), or era preference (modern vs classic).
    Do NOT say you're ready — only ask.
    Under 25 words. No greeting. Just the question.
  PROMPT

  # Turn 2: always ask — author familiarity, anchored to the current genre/mood
  THIRD_TURN_PROMPT = <<~PROMPT.strip
    You are an expert reading guide. Look at the genre or mood that has emerged in this conversation.
    Check the user's reading history for a favourite author who writes in THAT specific genre or mood.
    If one exists: ask whether they'd enjoy another book by that author or want to discover a new voice in that same space.
    If no relevant favourite exists: ask whether they want a familiar voice (an author they already know) or a new discovery within the specific genre they've described.
    Do NOT ask about an unrelated prolific author just because the user has read them a lot.
    Do NOT say you're ready — only ask.
    Under 35 words. No greeting. Just the question.
  PROMPT

  # Turn 3+: strict checklist before [READY]; probe if answers have been vague
  FOLLOWUP_PROMPT = <<~PROMPT.strip
    You are an expert reading guide. Review the full conversation.
    Only respond with exactly "[READY]" if you can confirm ALL THREE of the following:
    1. A specific sub-genre or vibe (e.g. "hard sci-fi" not just "sci-fi"; "cozy mystery" not just "mystery").
    2. The desired emotional payoff (e.g. bleak, uplifting, funny, thought-provoking, escapist).
    3. A clear through-line to their reading history — either a book that parallels what they've loved,
       or a deliberate break they want to make from their usual taste.
    If any of the three is still vague or unconfirmed, ask ONE targeted question to close the gap.
    If the user's last answer was short or non-committal, probe deeper — do not accept a vague signal as sufficient.
    Under 30 words. No greeting. Just the question or [READY].
  PROMPT

  # Turn 10+: force finish
  FORCE_READY = "[READY]"

  def initialize(user, clarification: nil, messages: [], ollama_client: OllamaClient.new)
    @user = user
    @clarification = clarification
    @messages = messages
    @ollama_client = ollama_client
  end

  def call(&on_chunk)
    # Short-circuit if we've hit max turns — no need to call the LLM
    if turn_count >= MAX_TURNS
      on_chunk&.call(FORCE_READY)
      return
    end
    @ollama_client.chat_stream(messages: build_messages, &on_chunk)
  end

  private

  def turn_count
    @messages.count { |m| m[:role].to_s == "user" }
  end

  def preference_signals
    @preference_signals ||= @user.preferences.for_context.pluck(:signal)
  end

  def full_system_prompt
    base = system_prompt
    signals = preference_signals
    return base if signals.empty?
    "The following preferences are already known — do not ask about them again: #{signals.join(", ")}\n\n#{base}"
  end

  def system_prompt
    case turn_count
    when 0 then FIRST_TURN_PROMPT
    when 1 then SECOND_TURN_PROMPT
    when 2 then THIRD_TURN_PROMPT
    else FOLLOWUP_PROMPT
    end
  end

  def build_messages
    [
      {role: "system", content: full_system_prompt},
      {role: "user", content: context_message},
      *@messages
    ]
  end

  def context_message
    parts = []
    books = @user.books.order(read_at: :desc).limit(25)

    if books.any?
      lines = books.map { |b| "- \"#{b.title}\" by #{b.author} (#{b.rating})" }
      parts << "Reading history:\n#{lines.join("\n")}"

      prolific = books.group_by(&:author).select { |_, bs| bs.size >= 3 }.keys
      parts << "Authors read 3+ times: #{prolific.join(", ")}" if prolific.any?
    end

    signals = preference_signals
    parts << "Known preferences: #{signals.join(" · ")}" if signals.any?

    parts << "User's stated preference: #{@clarification}" if @clarification.present?
    parts.any? ? parts.join("\n\n") : "No reading history yet."
  end
end
