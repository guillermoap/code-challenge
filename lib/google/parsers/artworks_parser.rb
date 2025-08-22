# frozen_string_literal: true

require_relative 'base_parser'

module Google
  module Parsers
    class ArtworksParser < BaseParser
      protected

      def initialize_results
        { artworks: [] }
      end

      def results_key
        :artworks
      end

      def kc_selector
        'div[data-attrid^="kc:/visual_art/"], div[data-attrid^="kc:"]'
      end
    end
  end
end
