# frozen_string_literal: true

require_relative 'parsers/base_parser'
require_relative 'parsers/books_parser'
require_relative 'parsers/albums_parser'
require_relative 'parsers/films_parser'
require_relative 'parsers/artworks_parser'
require_relative 'parsers/parser_factory'

# Main entry point for parsing Google search results
# Supports multiple carousel types through a factory pattern
class GoogleSearchParser
  attr_reader :results

  def initialize(html_content = nil, file_path = nil)
    @html_content = html_content
    @file_path = file_path
    @results = { items: [] }
  end

  def parse
    parser = ParserFactory.create_parser(@html_content, @file_path)
    @results = parser.parse
  end

  private

  def validate_inputs
    return if @html_content || @file_path

    raise ArgumentError, 'Must provide either html_content or file_path'
  end
end
