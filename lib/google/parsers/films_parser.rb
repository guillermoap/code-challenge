# frozen_string_literal: true

require_relative 'base_parser'

module Google
  module Parsers
    class FilmsParser < BaseParser
      protected

      def initialize_results
        { films: [] }
      end

      def results_key
        :films
      end

      def kc_selector
        'div[data-attrid^="kc:/film/"], div[data-attrid^="kc:"]'
      end
    end
  end
end
