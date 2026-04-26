class BooksController < ApplicationController
  before_action :set_book, only: %i[show edit update destroy]

  def index
    @books = Current.user.books.recent

    @books = @books.by_rating(params[:rating]) if params[:rating].present?
    @books = @books.by_genre(params[:genre]) if params[:genre].present?
    @books = @books.search(params[:q]) if params[:q].present?

    @genres = Current.user.books.distinct.pluck(:genre).compact.sort
    @total = Current.user.books.count
  end

  def show
  end

  def new
    @book = Current.user.books.new
  end

  def create
    @book = Current.user.books.new(book_params)

    if @book.save
      redirect_to books_path, notice: "Book added to your library."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @book.update(book_params)
      redirect_to book_path(@book), notice: "Book updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @book.destroy
    redirect_to books_path, notice: "Book removed from library."
  end

  private

  def set_book
    @book = Current.user.books.find(params[:id])
  end

  def book_params
    params.expect(book: [:title, :author, :year, :genre, :rating, :mood, :pace, :notes, :cover_url, :read_at])
  end
end
