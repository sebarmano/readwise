class Books::SearchController < ApplicationController
  def show
    render json: BookSearchService.search(params[:q].to_s)
  end
end
