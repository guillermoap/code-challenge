# frozen_string_literal: true

require 'spec_helper'
require 'google/parsers/default_parser'

RSpec.describe Google::Parsers::DefaultParser do
  describe '.new' do
    context 'when initialized with html_content' do
      let(:html_content) { '<html><div data-attrid="kc:/unknown/type">Test</div></html>' }
      subject { described_class.new(html_content) }

      it 'creates a parser with items results structure' do
        expect(subject.results).to eq({ items: [] })
      end
    end
  end

  describe '#parse' do
    let(:html_content) do
      '<html><div data-attrid="kc:/unknown/type">
        <div>
          <a href="/search?q=test">Test Item</a>
          <img src="https://example.com/test.jpg" alt="Test">
        </div>
      </div></html>'
    end
    let(:parser) { described_class.new(html_content) }
    subject { parser.parse }

    before { subject }

    it 'parses items into generic structure' do
      expect(parser.results[:items]).to be_an(Array)
    end

    it 'extracts item names correctly' do
      expect(parser.results[:items].first[:name]).to eq('Test Item')
    end

    it 'extracts valid image URLs' do
      parser.results[:items].each do |item|
        next unless item[:img]

        expect(item[:img]).to start_with('data:image/').or start_with('https://').or start_with('http://')
      end
    end

    it 'extracts valid Google search links' do
      parser.results[:items].each do |item|
        expect(item[:link]).to start_with('https://www.google.com/search')
      end
    end
  end
end
