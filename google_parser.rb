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
      name_and_date = get_name_and_date(div)

      @artworks[:artworks] << {
        link: link,
        img: img,
        name: name_and_date[:name],
        date: name_and_date[:date]
      }
    end
  end

  private

  def parent_divs
    first_kc_div = @doc.at_css('div[data-attrid^="kc:"]')

    return [] unless first_kc_div

    parent_divs = []
    processed_divs = Set.new

    divs_to_process = first_kc_div.css('div').select { |div| has_both_a_and_img(div) }

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

  def get_name_and_date(tag)
    name = nil
    date = nil

    # Try to get name from anchor tag text
    anchor = tag.at_css('a')
    if anchor && !anchor.text.strip.empty?
      raw_text = anchor.text.strip.gsub(/\s+/, ' ')

      # Check if the text contains a year at the end
      if raw_text.match?(/(.+?)(\d{4})$/)
        name = raw_text.gsub(/\d{4}$/, '').strip
        date = raw_text.match(/(\d{4})$/)[1]
      else
        name = raw_text
      end
    end

    # If no name from anchor, try img alt attribute
    unless name
      img = tag.at_css('img')
      if img && img['alt'] && !img['alt'].strip.empty?
        raw_text = img['alt'].strip.gsub(/\s+/, ' ')

        # Check if alt text contains a year at the end
        if raw_text.match?(/(.+?)(\d{4})$/)
          name = raw_text.gsub(/\d{4}$/, '').strip
          date = raw_text.match(/(\d{4})$/)[1]
        else
          name = raw_text
        end
      end
    end

    # If no name yet, look for name in first meaningful div
    unless name
      tag.css('div').each do |div|
        raw_text = div.text.strip.gsub(/\s+/, ' ')
        # Skip if it's just a date or too short
        next if raw_text.match?(/^\d{4}$/) || raw_text.length < 3

        # Check if it has a year at the end
        if raw_text.match?(/(.+?)(\d{4})$/)
          potential_name = raw_text.gsub(/\d{4}$/, '').strip
          # Only use if there's meaningful content after removing the year
          if potential_name.length > 2
            name = potential_name
            date = raw_text.match(/(\d{4})$/)[1]
          end
        else
          # It's just text without a year, use as name
          name = raw_text
        end
        break if name
      end
    end

    # Look for date in div text content
    unless date
      tag.css('div').each do |div|
        raw_text = div.text.strip.gsub(/\s+/, ' ')
        if raw_text.match?(/^\d{4}$/) || raw_text.match?(/\b(19|20)\d{2}\b/)
          date = raw_text.match(/(\d{4})$/)[1]
          break
        end
      end
    end

    { name: name, date: date }
  end

  def get_full_src(id)
    @scripts ||= @doc.css('script').map(&:content).join("\n")

    block = @scripts[/\{[^{}]*#{Regexp.escape(id)}[^{}]*\}/m]
    return nil unless block

    block[%r{(data:image/[^'"\s\}\]]+)}, 1]
  end
end
