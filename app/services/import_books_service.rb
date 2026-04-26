require "csv"

class ImportBooksService
  VALID_RATINGS = Book.ratings.keys.freeze

  def initialize(file, user)
    @file = file
    @user = user
  end

  def call
    imported = 0
    skipped = 0
    errors = []

    CSV.parse(read_file, headers: true, header_converters: :symbol) do |row|
      case process_row(row)
      in :imported then imported += 1
      in :skipped then skipped += 1
      in String => msg then errors << msg
      end
    end

    {imported:, skipped:, errors:}
  end

  private

  def read_file
    @file.respond_to?(:read) ? @file.read : @file.to_s
  end

  def process_row(row)
    title = row[:title]&.strip
    author = row[:author]&.strip
    rating = row[:rating]&.strip&.downcase

    return "Missing title on row: #{row.to_h}" if title.blank?
    return "Missing author for '#{title}'" if author.blank?

    unless VALID_RATINGS.include?(rating)
      return "Invalid rating '#{rating}' for '#{title}' (valid: #{VALID_RATINGS.join(", ")})"
    end

    return :skipped if @user.books.where("LOWER(title) = ?", title.downcase).exists?

    @user.books.create!(
      title:,
      author:,
      rating:,
      genre: row[:genre]&.strip.presence,
      year: row[:year_read]&.to_i.presence,
      notes: row[:notes]&.strip.presence
    )
    :imported
  rescue ActiveRecord::RecordInvalid => e
    e.message
  end
end
