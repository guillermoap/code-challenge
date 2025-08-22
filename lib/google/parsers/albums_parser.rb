# frozen_string_literal: true

require_relative 'base_parser'

module Google
  module Parsers
    class AlbumsParser < BaseParser
      protected

      def initialize_results
        { albums: [] }
      end

      def results_key
        :albums
      end

      def kc_selector
        'div[data-attrid^="kc:/music/"], div[data-attrid^="kc:"]'
      end
    end
  end
end
