# frozen_string_literal: true

require 'spec_helper'
require 'google/parsers/films_parser'

RSpec.describe Google::Parsers::FilmsParser do
  let(:fixture_path) { 'spec/fixtures/films' }
  let(:input_file) { File.join(fixture_path, 'input.html') }
  let(:output_file) { File.join(fixture_path, 'output.json') }
  let(:html_content) { File.read(input_file) }
  let(:expected_output) { JSON.parse(File.read(output_file), symbolize_names: true) }

  describe '.new' do
    context 'when initialized with html_content' do
      subject { described_class.new(html_content) }

      it 'creates a parser with films results structure' do
        expect(subject.results).to eq({ films: [] })
      end
    end
  end

  describe '#parse' do
    let(:parser) { described_class.new(html_content) }
    subject { parser.parse }

    before { subject }

    it 'parses the expected number of films' do
      expect(parser.results[:films].length).to eq(expected_output[:films].length)
    end

    it 'extracts film names correctly' do
      actual_names = parser.results[:films].map { |film| film[:name] }
      expected_names = expected_output[:films].map { |film| film[:name] }

      expect(actual_names).to match_array(expected_names)
    end

    it 'extracts extensions correctly' do
      films_with_extensions = parser.results[:films].select do |film|
        film[:extensions]&.any?
      end

      expect(films_with_extensions).not_to be_empty
    end

    it 'extracts valid image URLs' do
      parser.results[:films].each do |film|
        next unless film[:img]

        expect(film[:img]).to start_with('data:image/').or start_with('https://').or start_with('http://')
      end
    end

    it 'extracts valid Google search links' do
      parser.results[:films].each do |film|
        expect(film[:link]).to start_with('https://www.google.com/search')
      end
    end
  end
end
