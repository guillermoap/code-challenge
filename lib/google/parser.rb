# frozen_string_literal: true

require_relative 'parsers/factory'

module Google
  class Parser
    def self.parse(html_content = nil, file_path = nil)
      parser = Parsers::Factory.create_parser(html_content, file_path)
      parser.parse
    end
  end
end
