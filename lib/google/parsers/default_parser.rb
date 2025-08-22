# frozen_string_literal: true

require_relative 'base_parser'

module Google
  module Parsers
    class DefaultParser < BaseParser
      protected

      def initialize_results
        { items: [] }
      end

      def results_key
        :items
      end
    end
  end
end