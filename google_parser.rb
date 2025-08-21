# frozen_string_literal: true

require 'byebug'
require 'nokogiri'

class GoogleParser
  attr_reader :artworks

  def initialize(html_content = nil, file_path = nil)
    if file_path
      @doc = File.open(file_path) { |f| Nokogiri::HTML(f) }
    elsif html_content
      @doc = Nokogiri::HTML(html_content)
    else
      raise ArgumentError, 'Must provide either html_content or file_path'
    end

    @artworks = { artworks: [] }
  end

  def parse
    parent_divs.each do |div|
      link = get_link(div)
      img = get_img(div)

      @artworks[:artworks] << { link:, img: }
    end
  end

  private

  def parent_divs
    first_kc_div = @doc.at_css('div[data-attrid^="kc:"]')

    return [] unless first_kc_div

    parent_divs = []
    processed_divs = Set.new

    divs_to_process = first_kc_div.children.select { |child| child.name == 'div' }

    until divs_to_process.empty?
      current_div = divs_to_process.shift

      next if processed_divs.include?(current_div)

      processed_divs.add(current_div)

      next unless has_both_a_and_img(current_div)

      children_with_both = current_div.children.select do |child|
        child.name == 'div' && has_both_a_and_img(child) && !processed_divs.include?(child)
      end

      if children_with_both.empty?
        parent_divs << current_div unless parent_divs.include?(current_div)

        siblings = current_div.parent.children.select do |sibling|
          sibling.name == 'div' && sibling != current_div &&
            has_both_a_and_img(sibling) && !processed_divs.include?(sibling)
        end
        divs_to_process.concat(siblings)
      else
        divs_to_process.concat(children_with_both)
      end
    end

    parent_divs
  end

  def has_both_a_and_img(div)
    has_a = div.css('a').any?
    has_img = div.css('img').any?
    has_a && has_img
  end

  def get_link(tag)
    href = tag.at_css('a[href^="/search"]')['href']
    "https://www.google.com#{href}"
  end

  def get_img(tag)
    img_tag = tag.at_css('img[data-src]') || tag.at_css('img:not([data-src])')
    src = img_tag['data-src'] || img_tag['src']
    id = img_tag['id']

    if img_tag['data-deferred'] == '1'
      get_full_src(id)
    else
      src
    end
  end

  def get_full_src(id)
    @scripts ||= @doc.css('script').map(&:content).join("\n")

    block = @scripts[/\{[^{}]*#{Regexp.escape(id)}[^{}]*\}/m]
    return nil unless block

    block[%r{(data:image/[^'"\s\}\]]+)}, 1]
  end
end
