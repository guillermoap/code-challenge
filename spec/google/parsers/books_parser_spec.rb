# frozen_string_literal: true

require 'spec_helper'
require 'google/parsers/books_parser'

RSpec.describe Google::Parsers::BooksParser do
  let(:fixture_path) { 'spec/fixtures/books' }
  let(:input_file) { File.join(fixture_path, 'input.html') }
  let(:output_file) { File.join(fixture_path, 'output.json') }
  let(:html_content) { File.read(input_file) }
  let(:expected_output) { JSON.parse(File.read(output_file), symbolize_names: true) }

  describe '.new' do
    context 'when initialized with html_content' do
      subject { described_class.new(html_content) }

      it 'creates a parser with books results structure' do
        expect(subject.results).to eq({ books: [] })
      end
    end
  end

  describe '#parse' do
    let(:parser) { described_class.new(html_content) }
    subject { parser.parse }

    before { subject }

    it 'parses the expected number of books' do
      expect(parser.results[:books].length).to eq(expected_output[:books].length)
    end

    it 'extracts book names correctly' do
      actual_names = parser.results[:books].map { |book| book[:name] }
      expected_names = expected_output[:books].map { |book| book[:name] }

      expect(actual_names).to match_array(expected_names)
    end

    it 'extracts publication years' do
      books_with_years = parser.results[:books].select do |book|
        book[:extensions]&.any? { |ext| ext.match?(/^\d{4}$/) }
      end

      expect(books_with_years).not_to be_empty
    end

    it 'extracts valid image URLs' do
      parser.results[:books].each do |book|
        next unless book[:img]

        expect(book[:img]).to start_with('data:image/').or start_with('https://').or start_with('http://')
      end
    end

    it 'extracts valid Google search links' do
      parser.results[:books].each do |book|
        expect(book[:link]).to start_with('https://www.google.com/search')
      end
    end
  end
end
