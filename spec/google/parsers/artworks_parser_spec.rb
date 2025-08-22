# frozen_string_literal: true

require 'spec_helper'
require 'google/parsers/artworks_parser'

RSpec.describe Google::Parsers::ArtworksParser do
  let(:fixture_path) { 'spec/fixtures/artworks' }
  let(:input_file) { File.join(fixture_path, 'input.html') }
  let(:output_file) { File.join(fixture_path, 'output.json') }
  let(:html_content) { File.read(input_file) }
  let(:expected_output) { JSON.parse(File.read(output_file), symbolize_names: true) }

  describe '.new' do
    context 'when initialized with html_content' do
      subject { described_class.new(html_content) }

      it 'creates a parser with artworks results structure' do
        expect(subject.results).to eq({ artworks: [] })
      end
    end

    context 'when initialized with file_path' do
      subject { described_class.new(nil, input_file) }

      it 'creates a parser with artworks results structure' do
        expect(subject.results).to eq({ artworks: [] })
      end
    end
  end

  describe '#parse' do
    let(:parser) { described_class.new(html_content) }
    subject { parser.parse }

    before { subject }

    it 'parses the expected number of artworks' do
      expect(parser.results[:artworks].length).to eq(expected_output[:artworks].length)
    end

    it 'extracts artwork names correctly' do
      actual_names = parser.results[:artworks].map { |artwork| artwork[:name] }
      expected_names = expected_output[:artworks].map { |artwork| artwork[:name] }

      expect(actual_names).to match_array(expected_names)
    end

    it 'extracts extensions correctly' do
      parser.results[:artworks].each_with_index do |artwork, index|
        expected_artwork = expected_output[:artworks][index]
        expect(artwork[:extensions]).to match_array(expected_artwork[:extensions]) if expected_artwork[:extensions]
      end
    end

    it 'extracts valid image URLs' do
      parser.results[:artworks].each do |artwork|
        next unless artwork[:img]

        expect(artwork[:img]).to start_with('data:image/').or start_with('https://').or start_with('http://')
      end
    end

    it 'extracts valid Google search links' do
      parser.results[:artworks].each do |artwork|
        expect(artwork[:link]).to start_with('https://www.google.com/search')
      end
    end
  end

  describe 'edge cases' do
    subject { parser.parse }

    context 'with malformed HTML' do
      let(:parser) { described_class.new('<div><a href="/search?q=test">Test</div>') }

      it 'handles malformed HTML gracefully' do
        expect { subject }.not_to raise_error
      end
    end

    context 'with missing KC div' do
      let(:parser) { described_class.new('<html><body><div>No KC div here</div></body></html>') }

      it 'returns empty artworks array' do
        subject
        expect(parser.results[:artworks]).to be_empty
      end
    end
  end
end
