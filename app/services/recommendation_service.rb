require "json"

class RecommendationService
  def initialize(user, clarification: nil, messages: [], ollama_client: OllamaClient.new)
    @user = user
    @clarification = clarification
    @messages = messages
    @ollama_client = ollama_client
  end

  def prompt
    parts = [reading_history_section]
    parts << preferences_section if preference_signals.any?
    parts << claude_recs_section if claude_recs.any?
    parts << friend_recs_section if pending_friend_recs.any?
    parts << "## User preference\n#{@clarification}" if @clarification
    parts << conversation_section if @messages.any?
    parts << instructions
    parts.join("\n\n")
  end

  def call
    full_response = ""
    @ollama_client.chat_stream(messages: [{role: "user", content: prompt}]) do |chunk|
      full_response += chunk
    end
    parsed = JSON.parse(extract_json(full_response))
    persist(parsed)
  end

  private

  def preference_signals
    @preference_signals ||= @user.preferences.for_context.pluck(:signal)
  end

  def preferences_section
    "## Known preferences\n#{preference_signals.join(" · ")}"
  end

  def reading_history_section
    books = @user.books.order(read_at: :desc).limit(50)
    lines = books.map { |b| "- \"#{b.title}\" by #{b.author} (#{b.genre}, #{b.year}) — #{b.rating}, #{b.pace}, #{b.mood}" }
    "## Reading History\n#{lines.join("\n")}"
  end

  def claude_recs_section
    lines = claude_recs.map { |r| "- \"#{r.book_title}\" by #{r.book_author} — #{r.status}#{outcome_label(r)}" }
    "## Past Claude Recommendations\n#{lines.join("\n")}"
  end

  def friend_recs_section
    lines = pending_friend_recs.map do |r|
      taste = taste_score(r.recommender)
      "- \"#{r.book_title}\" by #{r.book_author} — from #{r.recommender.name}#{taste}"
    end
    "## Friend Recommendations (active)\n#{lines.join("\n")}"
  end

  def instructions
    <<~PROMPT.strip
      ## Task
      Suggest 3–5 books based on the reading history and conversation above.

      Rules:
      - Do NOT suggest books already in the reading history.
      - Respect author preferences expressed in the conversation. If not discussed, include a mix
        of authors they know and new discoveries.
      - When asked for "something like X by Author Y", recommend other authors in a similar style.
      - Prioritise variety: different authors, eras, and styles unless the user asked otherwise.

      For each book's "reason" field (max 60 words, must have BOTH parts):
      Part 1 — Personal bridge: name one specific book from their reading history that creates
        a clear through-line. E.g. "If you loved [Title], this delivers the same [quality]..."
      Part 2 — Social proof: add one concrete validation signal such as a major award won,
        film/TV adaptation, Goodreads rating with count, NYT bestseller duration, or cult status.

      Return ONLY a JSON array, no other text:
      [{"title":"...","author":"...","genre":"...","reason":"...","source":"claude"}]
    PROMPT
  end

  def claude_recs
    @claude_recs ||= @user.recommendations
      .joins(:recommender)
      .where(recommenders: {recommender_type: :claude})
      .order(created_at: :desc)
  end

  def pending_friend_recs
    @pending_friend_recs ||= @user.recommendations
      .joins(:recommender)
      .where(recommenders: {recommender_type: :friend})
      .active
      .includes(:recommender)
      .order(created_at: :desc)
  end

  def outcome_label(rec)
    rec.outcome_rating? ? ", outcome: #{rec.outcome_rating}" : ""
  end

  def taste_score(recommender)
    score = recommender.fiction_match || recommender.nonfiction_match
    score ? " (taste match: #{score.round(2)})" : ""
  end

  def extract_json(text)
    text[/\[.*\]/m] || "[]"
  end

  def conversation_section
    lines = @messages.map do |m|
      "#{(m[:role].to_s == "assistant") ? "Guide" : "User"}: #{m[:content]}"
    end
    "## Conversation\n#{lines.join("\n")}"
  end

  def persist(recs)
    return if recs.empty?
    recommender = claude_recommender
    @user.recommendations.where(recommender: recommender, status: :pending).destroy_all
    recs.each do |rec|
      @user.recommendations.create!(
        recommender: recommender,
        book_title: rec["title"],
        book_author: rec["author"],
        reason: rec["reason"],
        status: :pending
      )
    end
  end

  def claude_recommender
    @user.recommenders.find_or_create_by!(recommender_type: :claude) do |r|
      r.name = "Claude"
    end
  end
end
