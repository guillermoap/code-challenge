# frozen_string_literal: true

require_relative 'artworks_parser'
require_relative 'albums_parser'
require_relative 'books_parser'
require_relative 'films_parser'
require_relative 'default_parser'

module Google
  module Parsers
    class Factory
      KC_TYPE_MAPPINGS = {
        '/visual_art/' => ArtworksParser,
        '/music/' => AlbumsParser,
        '/book/' => BooksParser,
        '/film/' => FilmsParser
      }.freeze

      def self.create_parser(html_content = nil, file_path = nil)
        kc_type = detect_kc_type(html_content, file_path)
        parser_class = KC_TYPE_MAPPINGS[kc_type] || DefaultParser

        parser_class.new(html_content, file_path)
      end

      def self.detect_kc_type(html_content, file_path)
        doc = create_document(html_content, file_path)
        kc_div = doc.at_css('div[data-attrid^="kc:"]')

        return nil unless kc_div

        data_attrid = kc_div['data-attrid']
        KC_TYPE_MAPPINGS.keys.find { |key| data_attrid.include?(key) }
      end

      def self.create_document(html_content, file_path)
        if file_path
          File.open(file_path) { |f| Nokogiri::HTML(f) }
        else
          Nokogiri::HTML(html_content)
        end
      end
    end
  end
end
