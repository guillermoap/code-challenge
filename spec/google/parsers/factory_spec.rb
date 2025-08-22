# frozen_string_literal: true

require 'spec_helper'
require 'google/parsers/factory'

RSpec.describe Google::Parsers::Factory do
  describe '.create_parser' do
    subject { described_class.create_parser(html_content) }

    context 'with visual art KC data attribute' do
      let(:html_content) do
        '<html><div data-attrid="kc:/visual_art/visual_artist:works">Test</div></html>'
      end

      it 'returns an ArtworksParser' do
        expect(subject).to be_a(Google::Parsers::ArtworksParser)
      end

      it 'initializes with correct results structure' do
        expect(subject.results).to eq({ artworks: [] })
      end
    end

    context 'with music KC data attribute' do
      let(:html_content) do
        '<html><div data-attrid="kc:/music/artist:albums">Test</div></html>'
      end

      it 'returns an AlbumsParser' do
        expect(subject).to be_a(Google::Parsers::AlbumsParser)
      end

      it 'initializes with correct results structure' do
        expect(subject.results).to eq({ albums: [] })
      end
    end

    context 'with book KC data attribute' do
      let(:html_content) do
        '<html><div data-attrid="kc:/book/author:books">Test</div></html>'
      end

      it 'returns a BooksParser' do
        expect(subject).to be_a(Google::Parsers::BooksParser)
      end

      it 'initializes with correct results structure' do
        expect(subject.results).to eq({ books: [] })
      end
    end

    context 'with film KC data attribute' do
      let(:html_content) do
        '<html><div data-attrid="kc:/film/film_series:films">Test</div></html>'
      end

      it 'returns a FilmsParser' do
        expect(subject).to be_a(Google::Parsers::FilmsParser)
      end

      it 'initializes with correct results structure' do
        expect(subject.results).to eq({ films: [] })
      end
    end

    context 'with unknown KC data attribute' do
      let(:html_content) do
        '<html><div data-attrid="kc:/unknown/type:items">Test</div></html>'
      end

      it 'returns default DefaultParser' do
        expect(subject).to be_a(Google::Parsers::DefaultParser)
      end
    end

    context 'with no KC data attribute' do
      let(:html_content) do
        '<html><div>No KC div</div></html>'
      end

      it 'returns default DefaultParser' do
        expect(subject).to be_a(Google::Parsers::DefaultParser)
      end
    end
  end
end
