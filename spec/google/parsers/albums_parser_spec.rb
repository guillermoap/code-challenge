# frozen_string_literal: true

require 'spec_helper'
require 'google/parsers/albums_parser'

RSpec.describe Google::Parsers::AlbumsParser do
  let(:fixture_path) { 'spec/fixtures/albums' }
  let(:input_file) { File.join(fixture_path, 'input.html') }
  let(:output_file) { File.join(fixture_path, 'output.json') }
  let(:html_content) { File.read(input_file) }
  let(:expected_output) { JSON.parse(File.read(output_file), symbolize_names: true) }

  describe '.new' do
    context 'when initialized with html_content' do
      subject { described_class.new(html_content) }

      it 'creates a parser with albums results structure' do
        expect(subject.results).to eq({ albums: [] })
      end
    end
  end

  describe '#parse' do
    let(:parser) { described_class.new(html_content) }
    subject { parser.parse }

    before { subject }

    it 'parses the expected number of albums' do
      expect(parser.results[:albums].length).to eq(expected_output[:albums].length)
    end

    it 'extracts album names correctly' do
      actual_names = parser.results[:albums].map { |album| album[:name] }
      expected_names = expected_output[:albums].map { |album| album[:name] }

      expect(actual_names).to match_array(expected_names)
    end

    it 'extracts years in extensions' do
      albums_with_years = parser.results[:albums].select do |album|
        album[:extensions]&.any? { |ext| ext.match?(/^\d{4}$/) }
      end

      expect(albums_with_years).not_to be_empty
    end

    it 'handles albums without specific years' do
      albums_without_years = parser.results[:albums].select do |album|
        album[:extensions].nil? || album[:extensions].none? { |ext| ext.match?(/^\d{4}$/) }
      end

      expect(albums_without_years).to be_an(Array)
    end

    it 'extracts valid image URLs' do
      parser.results[:albums].each do |album|
        next unless album[:img]

        expect(album[:img]).to start_with('data:image/').or start_with('https://').or start_with('http://')
      end
    end

    it 'extracts valid Google search links' do
      parser.results[:albums].each do |album|
        expect(album[:link]).to start_with('https://www.google.com/search')
      end
    end
  end
end
