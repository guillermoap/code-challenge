# frozen_string_literal: true

require 'spec_helper'
require 'google/parser'

RSpec.describe Google::Parser do
  describe '.parse' do
    context 'with visual art HTML content' do
      let(:html_content) do
        '<html><div data-attrid="kc:/visual_art/visual_artist:works">
          <div>
            <a href="/search?q=Starry+Night">Starry Night</a>
            <img src="https://example.com/starry.jpg" alt="Starry Night">
          </div>
        </div></html>'
      end

      subject { described_class.parse(html_content) }

      it 'returns parsed artworks' do
        expect(subject).to have_key(:artworks)
        expect(subject[:artworks]).to be_an(Array)
      end

      it 'delegates to appropriate parser' do
        expect(Google::Parsers::Factory).to receive(:create_parser).with(html_content, nil).and_call_original
        subject
      end
    end

    context 'with music HTML content' do
      let(:html_content) do
        '<html><div data-attrid="kc:/music/artist:albums">
          <div>
            <a href="/search?q=Nevermind">Nevermind</a>
            <img src="https://example.com/nevermind.jpg" alt="Nevermind">
          </div>
        </div></html>'
      end

      subject { described_class.parse(html_content) }

      it 'returns parsed albums' do
        expect(subject).to have_key(:albums)
        expect(subject[:albums]).to be_an(Array)
      end
    end

    context 'with file path parameter' do
      let(:fixture_path) { 'spec/fixtures/artworks/input.html' }

      subject { described_class.parse(nil, fixture_path) }

      it 'parses from file path' do
        expect(subject).to have_key(:artworks)
        expect(subject[:artworks]).to be_an(Array)
      end

      it 'delegates to factory with file path' do
        expect(Google::Parsers::Factory).to receive(:create_parser).with(nil, fixture_path).and_call_original
        subject
      end
    end

    context 'with both html_content and file_path' do
      let(:html_content) { '<html><div data-attrid="kc:/visual_art/">Test</div></html>' }
      let(:file_path) { 'spec/fixtures/artworks/input.html' }

      subject { described_class.parse(html_content, file_path) }

      it 'passes both parameters to factory' do
        expect(Google::Parsers::Factory).to receive(:create_parser).with(html_content, file_path).and_call_original
        subject
      end
    end
  end
end
