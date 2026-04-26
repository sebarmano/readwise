require "csv"

class Books::ImportTemplatesController < ApplicationController
  HEADERS = %w[title author genre year_read rating notes].freeze

  def show
    csv = CSV.generate(headers: true) { |c| c << HEADERS }
    send_data csv, filename: "books_import_template.csv", type: "text/csv", disposition: "attachment"
  end
end
