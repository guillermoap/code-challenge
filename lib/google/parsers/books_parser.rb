# frozen_string_literal: true

require_relative 'base_parser'

module Google
  module Parsers
    class BooksParser < BaseParser
      protected

      def initialize_results
        { books: [] }
      end

      def results_key
        :books
      end

      def kc_selector
        'div[data-attrid^="kc:/book/"], div[data-attrid^="kc:"]'
      end
    end
  end
end
