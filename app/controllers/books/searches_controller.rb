class Books::SearchesController < ApplicationController
  def show
    render json: BookSearchService.search(params[:q].to_s)
  end
end
