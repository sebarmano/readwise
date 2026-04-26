class Books::ImportsController < ApplicationController
  def new
  end

  def create
    unless params[:file].present?
      flash.now[:alert] = "Please select a CSV file."
      return render :new, status: :unprocessable_entity
    end

    result = ImportBooksService.new(params[:file], Current.user).call
    @imported = result[:imported]
    @skipped = result[:skipped]
    @errors = result[:errors]
  end
end
