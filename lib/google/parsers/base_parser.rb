# frozen_string_literal: true

require 'nokogiri'
require_relative '../helpers/extractor_helpers'

module Google
  module Parsers
    class BaseParser
      include Helpers::ExtractorHelpers

      attr_reader :results

      def initialize(html_content = nil, file_path = nil)
        validate_inputs(html_content, file_path)
        @doc = create_document(html_content, file_path)
        @results = initialize_results
      end

      def parse
        parent_divs.each do |div|
          item = extract_item_data(div)
          add_item_to_results(item) if item_valid?(item)
        end
        @results
      end

      protected

      def initialize_results
        raise NotImplementedError, 'Subclasses must implement initialize_results'
      end

      def results_key
        raise NotImplementedError, 'Subclasses must implement results_key'
      end

      def extract_name(tag)
        extract_from_anchor(tag) ||
          extract_from_img_alt(tag) ||
          extract_from_div_text(tag)
      end

      def extract_extensions(tag)
        extensions = []
        name = extract_name(tag)

        tag.css('div').each do |div|
          if div.children.length > 1
            extensions.concat(extract_from_multi_child_div(div, name))
          else
            extensions.concat(extract_from_single_child_div(div, name))
          end
        end

        extensions.uniq.compact
      end

      def extract_image_url(tag)
        img_tag = find_image_tag(tag)
        return nil unless img_tag

        extract_image_source(img_tag)
      end

      def kc_selector
        'div[data-attrid^="kc:"]'
      end

      def item_container_selector
        'div'
      end

      def build_item_data(div)
        {
          name: extract_name(div),
          extensions: extract_extensions(div),
          link: extract_link_url(div),
          img: extract_image_url(div)
        }
      end

      private

      def validate_inputs(html_content, file_path)
        return if html_content || file_path

        raise ArgumentError, 'Must provide either html_content or file_path'
      end

      def create_document(html_content, file_path)
        if file_path
          File.open(file_path) { |f| Nokogiri::HTML(f) }
        else
          Nokogiri::HTML(html_content)
        end
      end

      def add_item_to_results(item)
        @results[results_key] << item
      end

      def parent_divs
        first_kc_div = @doc.at_css(kc_selector)
        return [] unless first_kc_div

        find_item_containers(first_kc_div)
      end

      def find_item_containers(kc_div)
        processed_divs = Set.new
        divs_to_process = kc_div.css(item_container_selector).select { |div| has_required_elements?(div) }

        result = []
        until divs_to_process.empty?
          current_div = divs_to_process.shift
          next if processed_divs.include?(current_div)

          processed_divs.add(current_div)
          next unless has_required_elements?(current_div)

          children_with_elements = find_children_with_elements(current_div, processed_divs)

          if children_with_elements.empty?
            result << current_div unless result.include?(current_div)
          else
            divs_to_process.concat(children_with_elements)
          end
        end

        result
      end

      def find_children_with_elements(div, processed_divs)
        div.children.select do |child|
          child.name == 'div' &&
            has_required_elements?(child) &&
            !processed_divs.include?(child)
        end
      end

      def extract_item_data(div)
        build_item_data(div)
      end

      def item_valid?(item)
        item[:name] && !item[:name].empty?
      end
    end
  end
end
