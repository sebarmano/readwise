# Seeds the development database with a demo user and a varied book library.
# Safe to re-run: books are skipped if the title already exists for that user.
#
#   bin/rails db:seed
#
# Login: dev@readwise.dev / password

user = User.find_or_create_by!(email_address: "dev@readwise.dev") do |u|
  u.password = "password"
  u.password_confirmation = "password"
end

BOOKS = [
  {
    title: "Beloved",
    author: "Toni Morrison",
    year: 1987,
    genre: "Fiction",
    rating: :loved,
    mood: "dark/emotional/literary",
    pace: "slow",
    read_at: "2025-01-10",
    notes: "Haunting and powerful. The prose is unlike anything else."
  },
  {
    title: "Sapiens",
    author: "Yuval Noah Harari",
    year: 2011,
    genre: "Non-Fiction",
    rating: :loved,
    mood: "educational/thought-provoking",
    pace: "medium",
    read_at: "2025-02-14",
    notes: "Changed how I think about human history."
  },
  {
    title: "Project Hail Mary",
    author: "Andy Weir",
    year: 2021,
    genre: "Sci-Fi",
    rating: :loved,
    mood: "adventure/uplifting/funny",
    pace: "fast",
    read_at: "2025-03-05",
    notes: "Pure fun. Best sci-fi I've read in years."
  },
  {
    title: "Dune",
    author: "Frank Herbert",
    year: 1965,
    genre: "Sci-Fi",
    rating: :loved,
    mood: "epic/dark/philosophical",
    pace: "slow",
    read_at: "2025-01-28",
    notes: "Dense but rewarding. The world-building is unmatched."
  },
  {
    title: "Atomic Habits",
    author: "James Clear",
    year: 2018,
    genre: "Self-Help",
    rating: :liked,
    mood: "motivational/practical",
    pace: "fast",
    read_at: "2025-02-28",
    notes: "Very practical. Some repetition but the 1% concept sticks."
  },
  {
    title: "Thinking, Fast and Slow",
    author: "Daniel Kahneman",
    year: 2011,
    genre: "Psychology",
    rating: :loved,
    mood: "educational/challenging",
    pace: "slow",
    read_at: "2025-01-25",
    notes: "Essential reading. Takes time but worth every page."
  },
  {
    title: "1984",
    author: "George Orwell",
    year: 1949,
    genre: "Fiction",
    rating: :loved,
    mood: "dark/dystopian/tense",
    pace: "medium",
    read_at: "2025-03-15",
    notes: "Still feels relevant. Unsettling in the best way."
  },
  {
    title: "The Hobbit",
    author: "J.R.R. Tolkien",
    year: 1937,
    genre: "Fantasy",
    rating: :liked,
    mood: "adventure/whimsical/cozy",
    pace: "medium",
    read_at: "2025-03-20",
    notes: "Charming and easy. Great palate cleanser."
  },
  {
    title: "Meditations",
    author: "Marcus Aurelius",
    year: 180,
    genre: "Philosophy",
    rating: :liked,
    mood: "reflective/philosophical/calming",
    pace: "slow",
    read_at: "2025-04-05",
    notes: "Read a few pages at a time. Genuinely useful."
  },
  {
    title: "The Alchemist",
    author: "Paulo Coelho",
    year: 1988,
    genre: "Fiction",
    rating: :meh,
    mood: "spiritual/inspirational",
    pace: "fast",
    read_at: "2025-03-01",
    notes: "Overhyped. The allegory is too on-the-nose for me."
  },
  {
    title: "Educated",
    author: "Tara Westover",
    year: 2018,
    genre: "Memoir",
    rating: :loved,
    mood: "emotional/inspiring/dark",
    pace: "fast",
    read_at: "2025-02-10",
    notes: "Couldn't put it down. Remarkable story."
  },
  {
    title: "Born to Run",
    author: "Christopher McDougall",
    year: 2009,
    genre: "Sports",
    rating: :liked,
    mood: "inspirational/adventurous",
    pace: "fast",
    read_at: "2025-04-10",
    notes: "Makes you want to go for a run immediately."
  },
  {
    title: "The Name of the Wind",
    author: "Patrick Rothfuss",
    year: 2007,
    genre: "Fantasy",
    rating: :liked,
    mood: "adventure/romantic/epic",
    pace: "medium",
    read_at: "2025-04-18",
    notes: "Beautiful prose. Just don't expect the sequel any time soon."
  },
  {
    title: "Quiet",
    author: "Susan Cain",
    year: 2012,
    genre: "Psychology",
    rating: :liked,
    mood: "educational/reflective",
    pace: "medium",
    read_at: "2025-02-20",
    notes: "Validating read if you're an introvert."
  },
  {
    title: "Shoe Dog",
    author: "Phil Knight",
    year: 2016,
    genre: "Memoir",
    rating: :loved,
    mood: "inspiring/tense/motivational",
    pace: "fast",
    read_at: "2025-03-28",
    notes: "The Nike origin story is genuinely gripping."
  },
  {
    title: "Man's Search for Meaning",
    author: "Viktor Frankl",
    year: 1946,
    genre: "Philosophy",
    rating: :loved,
    mood: "dark/profound/uplifting",
    pace: "slow",
    read_at: "2025-04-22",
    notes: "Short but one of the most important books I've read."
  },
  {
    title: "The Hitchhiker's Guide to the Galaxy",
    author: "Douglas Adams",
    year: 1979,
    genre: "Sci-Fi",
    rating: :loved,
    mood: "funny/whimsical/absurd",
    pace: "fast",
    read_at: "2025-04-15",
    notes: "42. That's all."
  },
  {
    title: "Never Split the Difference",
    author: "Chris Voss",
    year: 2016,
    genre: "Self-Help",
    rating: :meh,
    mood: "practical/tense",
    pace: "medium",
    read_at: "2025-03-10",
    notes: "Good anecdotes but feels padded past the core idea."
  },
  {
    title: "The Left Hand of Darkness",
    author: "Ursula K. Le Guin",
    year: 1969,
    genre: "Sci-Fi",
    rating: :liked,
    mood: "thought-provoking/atmospheric/literary",
    pace: "slow",
    read_at: "2025-04-02",
    notes: "Dense and rewarding. Le Guin at her most ambitious."
  },
  {
    title: "Bad Blood",
    author: "John Carreyrou",
    year: 2018,
    genre: "Non-Fiction",
    rating: :loved,
    mood: "tense/shocking/gripping",
    pace: "fast",
    read_at: "2025-03-22",
    notes: "Reads like a thriller. Insane that this actually happened."
  }
].freeze

created = 0
skipped = 0

BOOKS.each do |attrs|
  if user.books.exists?(title: attrs[:title])
    skipped += 1
  else
    user.books.create!(attrs)
    created += 1
  end
end

puts "Seeds done — #{created} created, #{skipped} already existed"
puts "Login: #{user.email_address} / password"
