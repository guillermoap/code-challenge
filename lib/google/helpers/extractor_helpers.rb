# frozen_string_literal: true

module Google
  module Helpers
    module ExtractorHelpers
      private

      def extract_from_anchor(tag)
        anchor = tag.at_css('a')
        return nil unless anchor && !anchor.text.strip.empty?

        raw_text = clean_text(anchor.text)
        extract_name_from_text(raw_text)
      end

      def extract_from_img_alt(tag)
        img = tag.at_css('img')
        return nil unless img && img['alt'] && !img['alt'].strip.empty?

        raw_text = clean_text(img['alt'])
        extract_name_from_text(raw_text)
      end

      def extract_from_div_text(tag)
        tag.css('div').each do |div|
          raw_text = clean_text(div.text)
          next if raw_text.length < 3 || year_only?(raw_text)

          return extract_name_from_text(raw_text) if raw_text.length > 5
        end
        nil
      end

      def extract_from_multi_child_div(div, excluded_name)
        extensions = []
        div.children.each do |child|
          next unless child.text?

          text = child.text.strip
          next if text.empty? || text == '·' || text == excluded_name

          extensions << text
        end
        extensions
      end

      def extract_from_single_child_div(div, excluded_name)
        text = div.text.strip
        return [] if text.empty? || text == '·' || text == excluded_name

        text.length < 20 ? [text] : []
      end

      def find_image_tag(tag)
        tag.at_css('img[data-src]') || tag.at_css('img:not([data-src])')
      end

      def extract_image_source(img_tag)
        url = if img_tag['data-deferred'] == '1'
                extract_full_image_source(img_tag['id'])
              else
                img_tag['data-src'] || img_tag['src']
              end

        normalize_image_url(url)
      end

      def normalize_image_url(url)
        return nil unless url

        if url.start_with?('//')
          "https:#{url}"
        else
          url
        end
      end

      def extract_full_image_source(img_id)
        return nil unless img_id

        scripts = @doc.css('script').map(&:content).join("\n")
        block = scripts[/\{[^{}]*#{Regexp.escape(img_id)}[^{}]*\}/m]
        return nil unless block

        block[%r{(data:image/[^'"\s\}\]]+)}, 1]
      end

      def extract_link_url(tag)
        anchor = tag.at_css('a[href^="/search"]')
        return nil unless anchor

        "https://www.google.com#{anchor['href']}"
      end

      def clean_text(text)
        text.strip.gsub(/\s+/, ' ')
      end

      def extract_name_from_text(text)
        if text.match?(/(.+?)(\d{4})$/)
          potential_name = text.gsub(/\d{4}$/, '').strip
          potential_name.length > 2 ? potential_name : text
        else
          text
        end
      end

      def year_only?(text)
        text.match?(/^\d{4}$/)
      end

      def has_required_elements?(div)
        has_anchor = div.css('a').any?
        has_image = div.css('img').any?
        has_anchor && has_image
      end
    end
  end
end
