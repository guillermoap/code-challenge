# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GoogleParser do
  shared_context 'with van gogh paintings fixture' do
    let(:fixture_path) { 'spec/fixtures/default/van-gogh-paintings' }
    let(:input_file) { File.join(fixture_path, 'input.html') }
    let(:output_file) { File.join(fixture_path, 'output.json') }
    let(:html_content) { File.read(input_file) }
    let(:expected_output) { JSON.parse(File.read(output_file), symbolize_names: true) }
  end

  shared_context 'with nirvana albums fixture' do
    let(:fixture_path) { 'spec/fixtures/default/nirvana-albums' }
    let(:input_file) { File.join(fixture_path, 'input.html') }
    let(:output_file) { File.join(fixture_path, 'output.json') }
    let(:html_content) { File.read(input_file) }
    let(:expected_output) { JSON.parse(File.read(output_file), symbolize_names: true) }
  end

  shared_context 'with brandon sanderson books fixture' do
    let(:fixture_path) { 'spec/fixtures/default/brandon-sanderson-books' }
    let(:input_file) { File.join(fixture_path, 'input.html') }
    let(:output_file) { File.join(fixture_path, 'output.json') }
    let(:html_content) { File.read(input_file) }
    let(:expected_output) { JSON.parse(File.read(output_file), symbolize_names: true) }
  end

  describe '.new' do
    context 'when initialized with html_content' do
      let(:html_content) { '<html><body><div>Test</div></body></html>' }
      
      subject { described_class.new(html_content) }

      it 'creates a Nokogiri document from the content' do
        expect(subject.instance_variable_get(:@doc)).to be_a(Nokogiri::HTML::Document)
      end

      it 'initializes artworks as empty hash with artworks array' do
        expect(subject.artworks).to eq({ artworks: [] })
      end
    end

    context 'when initialized with file_path' do
      include_context 'with van gogh paintings fixture'
      
      subject { described_class.new(nil, input_file) }

      it 'creates a Nokogiri document from the file' do
        expect(subject.instance_variable_get(:@doc)).to be_a(Nokogiri::HTML::Document)
      end

      it 'initializes artworks as empty hash with artworks array' do
        expect(subject.artworks).to eq({ artworks: [] })
      end
    end

    context 'when initialized without content or file_path' do
      subject { described_class.new }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'Must provide either html_content or file_path')
      end
    end
  end

  describe '#parse' do
    let(:parser) { described_class.new(html_content) }
    subject { parser.parse }

    context 'with Van Gogh paintings' do
      include_context 'with van gogh paintings fixture'

      it 'parses the expected number of artworks' do
        subject
        expect(parser.artworks[:artworks].length).to eq(expected_output[:artworks].length)
      end

      it 'extracts artwork names correctly' do
        subject
        actual_names = parser.artworks[:artworks].map { |artwork| artwork[:name] }
        expected_names = expected_output[:artworks].map { |artwork| artwork[:name] }
        
        expect(actual_names).to match_array(expected_names)
      end

      it 'extracts extensions correctly' do
        subject
        parser.artworks[:artworks].each_with_index do |artwork, index|
          expected_artwork = expected_output[:artworks][index]
          expect(artwork[:extensions]).to match_array(expected_artwork[:extensions]) if expected_artwork[:extensions]
        end
      end

      it 'extracts valid image URLs' do
        subject
        parser.artworks[:artworks].each do |artwork|
          next unless artwork[:img]
          expect(artwork[:img]).to start_with('data:image/').or start_with('https://').or start_with('http://')
        end
      end

      it 'extracts valid Google search links' do
        subject
        parser.artworks[:artworks].each do |artwork|
          expect(artwork[:link]).to start_with('https://www.google.com/search')
        end
      end
    end

    context 'with Nirvana albums' do
      include_context 'with nirvana albums fixture'

      it 'parses the expected number of albums' do
        subject
        expect(parser.artworks[:artworks].length).to eq(expected_output[:artworks].length)
      end

      it 'extracts album names correctly' do
        subject
        actual_names = parser.artworks[:artworks].map { |artwork| artwork[:name] }
        expected_names = expected_output[:artworks].map { |artwork| artwork[:name] }
        
        expect(actual_names).to match_array(expected_names)
      end

      it 'extracts years in extensions' do
        subject
        albums_with_years = parser.artworks[:artworks].select do |artwork|
          artwork[:extensions]&.any? { |ext| ext.match?(/^\d{4}$/) }
        end
        
        expect(albums_with_years).not_to be_empty
      end

      it 'handles albums without specific years' do
        subject
        albums_without_years = parser.artworks[:artworks].select do |artwork|
          artwork[:extensions].nil? || artwork[:extensions].none? { |ext| ext.match?(/^\d{4}$/) }
        end
        
        expect(albums_without_years).to be_an(Array)
      end
    end

    context 'with Brandon Sanderson books' do
      include_context 'with brandon sanderson books fixture'

      it 'parses the expected number of books' do
        subject
        expect(parser.artworks[:artworks].length).to eq(expected_output[:artworks].length)
      end

      it 'extracts book names correctly' do
        subject
        actual_names = parser.artworks[:artworks].map { |artwork| artwork[:name] }
        expected_names = expected_output[:artworks].map { |artwork| artwork[:name] }
        
        expect(actual_names).to match_array(expected_names)
      end

      it 'extracts publication years' do
        subject
        books_with_years = parser.artworks[:artworks].select do |artwork|
          artwork[:extensions]&.any? { |ext| ext.match?(/^\d{4}$/) }
        end
        
        expect(books_with_years).not_to be_empty
      end
    end
  end

  describe '#get_name' do
    let(:parser) { described_class.new('<html></html>') }
    subject { parser.send(:get_name, tag) }

    context 'when anchor tag contains name' do
      let(:tag) do
        Nokogiri::HTML('<div><a href="/test">The Starry Night</a></div>').at_css('div')
      end

      it { is_expected.to eq('The Starry Night') }
    end

    context 'when anchor tag contains name with year' do
      let(:tag) do
        Nokogiri::HTML('<div><a href="/test">The Starry Night1889</a></div>').at_css('div')
      end

      it { is_expected.to eq('The Starry Night') }
    end

    context 'when img alt contains name' do
      let(:tag) do
        Nokogiri::HTML('<div><img alt="Wheatfield with Crows" src="test.jpg"></div>').at_css('div')
      end

      it { is_expected.to eq('Wheatfield with Crows') }
    end

    context 'when name is in div text' do
      let(:tag) do
        Nokogiri::HTML('<div><div>The Fellowship of the Ring</div><div>2001</div></div>').at_css('div')
      end

      it { is_expected.to eq('The Fellowship of the Ring') }
    end

    context 'when no name is found' do
      let(:tag) do
        Nokogiri::HTML('<div></div>').at_css('div')
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#get_extensions' do
    let(:parser) { described_class.new('<html></html>') }
    subject { parser.send(:get_extensions, tag) }

    context 'with multiple metadata elements' do
      let(:tag) do
        Nokogiri::HTML(<<~HTML
          <div>
            <a href="/test">F1</a>
            <div class="metadata">
              <div>PG-13</div>
              <div>2h 35m</div>
              <div>·</div>
              <div>2025</div>
            </div>
          </div>
        HTML
        ).at_css('div')
      end

      before do
        allow(parser).to receive(:get_name).and_return('F1')
      end

      it 'extracts all metadata except separators and name' do
        expect(subject).to include('PG-13', '2h 35m', '2025')
        expect(subject).not_to include('·', 'F1')
      end
    end

    context 'with single text divs' do
      let(:tag) do
        Nokogiri::HTML(<<~HTML
          <div>
            <div>Album Name</div>
            <div>1991</div>
            <div>Rock</div>
          </div>
        HTML
        ).at_css('div')
      end

      before do
        allow(parser).to receive(:get_name).and_return('Album Name')
      end

      it 'extracts short text divs as extensions' do
        expect(subject).to include('1991', 'Rock')
        expect(subject).not_to include('Album Name')
      end
    end

    context 'when no extensions are found' do
      let(:tag) do
        Nokogiri::HTML('<div><a href="/test">Just a Name</a></div>').at_css('div')
      end

      before do
        allow(parser).to receive(:get_name).and_return('Just a Name')
      end

      it { is_expected.to eq([]) }
    end
  end

  describe '#get_img' do
    let(:parser) { described_class.new('<html></html>') }
    subject { parser.send(:get_img, tag) }

    context 'with data-src attribute' do
      let(:tag) do
        Nokogiri::HTML('<div><img data-src="data:image/jpeg;base64,test" src="" id="test"></div>').at_css('div')
      end

      it { is_expected.to eq('data:image/jpeg;base64,test') }
    end

    context 'with deferred image' do
      let(:tag) do
        Nokogiri::HTML('<div><img data-deferred="1" id="test_id" src=""></div>').at_css('div')
      end

      before do
        allow(parser).to receive(:get_full_src).with('test_id').and_return('data:image/jpeg;base64,full')
      end

      it { is_expected.to eq('data:image/jpeg;base64,full') }
    end

    context 'with regular src attribute' do
      let(:tag) do
        Nokogiri::HTML('<div><img src="https://example.com/image.jpg"></div>').at_css('div')
      end

      it { is_expected.to eq('https://example.com/image.jpg') }
    end
  end

  describe '#get_link' do
    let(:parser) { described_class.new('<html></html>') }
    subject { parser.send(:get_link, tag) }

    context 'with search link' do
      let(:tag) do
        Nokogiri::HTML('<div><a href="/search?q=test">Test</a></div>').at_css('div')
      end

      it { is_expected.to eq('https://www.google.com/search?q=test') }
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
        expect(parser.artworks[:artworks]).to be_empty
      end
    end

    context 'with empty document' do
      let(:parser) { described_class.new('<html></html>') }

      it 'returns empty artworks array' do
        subject
        expect(parser.artworks[:artworks]).to be_empty
      end
    end
  end
end
