# Google Carrousel Parser Architecture

## Overview

This solution implements a scalable, maintainable parser for Google search result carousels using established design patterns and clean architecture principles.

## Key Benefits

### 1. **Extensibility**
Adding support for new carousel types is straightforward. For example, to support Brad Pitt movies (`kc:/tvm/w2w:enriched_recomendation_list`):

```ruby
# lib/google/parsers/enriched_recommendation_list_parser.rb
class EnrichedRecommendationListParser < BaseParser
  protected

  def initialize_results
    { recommendations: [] }
  end

  def results_key
    :recommendations
  end

  def kc_selector
    'div[data-attrid^="kc:/tvm/"], div[data-attrid^="kc:"]'
  end

  # Custom new logic to support different carousel structure
  # Override methods as needed for this specific layout
  
  # Example: Enriched recommendation lists may have different item detection
  # def has_required_elements?(div)
  #   # Custom logic for this carousel type's structure
  # end
  #
  # def extract_name(tag)
  #   # Custom name extraction for recommendation format
  # end
end
```

Then add one line to the factory:
```ruby
KC_TYPE_MAPPINGS = {
  # existing mappings...
  '/tvm/' => EnrichedRecommendationListParser
}.freeze
```

### 2. **Maintainability**
- **Single Responsibility**: Each parser handles one carousel type
- **DRY Principle**: Common extraction logic is shared via `ExtractorHelpers`
- **Clear Separation**: Business logic separated from HTML parsing details

### 3. **Testability**
- Each component can be tested in isolation
- Fixtures provide consistent test data
- Mocking and stubbing are straightforward due to clear interfaces

### 4. **Robustness**
- Graceful handling of malformed HTML
- Protocol-relative URL normalization (`//example.com` → `https://example.com`)
- Fallback to default parser when carousel type is unknown

## Architecture Overview

### Factory Pattern
The `Google::Parsers::Factory` automatically selects the appropriate parser based on the `data-attrid` attribute:

```ruby
# Detects kc:/music/ → returns AlbumsParser
# Detects kc:/book/ → returns BooksParser  
# Unknown type → returns DefaultParser (default)
```

### Template Method Pattern
`BaseParser` defines the parsing workflow while allowing subclasses to customize specific behaviors:

```ruby
def parse
  parent_divs.each do |div|
    item = extract_item_data(div)
    add_item_to_results(item) if item_valid?(item)
  end
  @results
end
```

### Shared Utilities
`ExtractorHelpers` provides reusable extraction methods:
- Name extraction from anchors, image alt text, or div content
- Extension/metadata parsing
- Image URL handling with protocol normalization
- Google search link generation

## How It Works

### High-Level Flow
1. **Entry Point**: `Google::Parser.parse(html_content)` 
2. **Factory Selection**: Factory analyzes HTML and selects appropriate parser
3. **Template Execution**: Selected parser follows the template method workflow
4. **Data Extraction**: Parser uses helper methods to extract structured data
5. **Result Assembly**: Returns hash with appropriate key (`artworks`, `albums`, etc.)

### Generic Structure Detection

The parser is designed to be **structure-agnostic** and relies on Google's consistent patterns rather than brittle HTML selectors:

#### 1. **KC Div Detection**
```ruby
def kc_selector
  'div[data-attrid^="kc:"]'  # Finds any Google Knowledge Card div
end
```
The parser first locates the main carousel container using Google's `kc:` data attributes. This is Google's own semantic marker, making it reliable across layout changes.

#### 2. **Smart Parent Div Discovery**
```ruby
def find_item_containers(kc_div)
  processed_divs = Set.new
  divs_to_process = kc_div.css('div').select { |div| has_required_elements?(div) }
  
  until divs_to_process.empty?
    current_div = divs_to_process.shift
    # Process current div and add children to queue if needed
  end
end
```
Instead of hardcoding specific CSS paths, we **iteratively traverse** the DOM using a breadth-first approach to find divs that contain both:
- An anchor tag (`<a>`) for the clickable link
- An image tag (`<img>`) for the thumbnail

The algorithm uses a queue-based iteration that processes each div level by level, avoiding infinite loops with a `processed_divs` Set. This approach works regardless of nesting depth or intermediate wrapper divs.

#### 3. **Flexible Content Extraction**
```ruby
def extract_name(tag)
  extract_from_anchor(tag) ||      # Try anchor text first
    extract_from_img_alt(tag) ||   # Fallback to image alt
    extract_from_div_text(tag)     # Last resort: div content
end
```
The name extraction follows a **priority cascade**:
1. **Anchor text**: `<a>The Starry Night</a>`
2. **Image alt**: `<img alt="The Starry Night">`
3. **Div content**: `<div>The Starry Night</div>`

This multi-fallback approach ensures we capture content even if Google reorganizes their HTML structure.

#### 4. **Intelligent Extension Parsing**
```ruby
def extract_extensions(tag)
  extensions = []
  name = extract_name(tag)
  
  tag.css('div').each do |div|
    if div.children.length > 1
      extensions.concat(extract_from_multi_child_div(div, name))
    else
      extensions.concat(extract_from_single_child_div(div, name))
    end
  end
end
```
Extensions (dates, genres, etc.) are extracted by:
- Scanning all child divs within an item
- Identifying text nodes that aren't the main name
- Filtering out decorative elements (middle dots, empty strings)
- Handling both single-text and multi-text container patterns

### Resilience to HTML Changes

This architecture is resilient because it relies on **semantic patterns** rather than brittle selectors:

- **KC Data Attributes**: Google's own semantic markers  
- **Content-Based Detection**: Looks for anchor + image combinations  
- **Multiple Extraction Paths**: Falls back gracefully when structure changes  
- **Iterative Tree Traversal**: Breadth-first search adapts to different nesting levels  
- **Text Pattern Recognition**: Identifies content by meaning, not position  

### Why This Works Across Carousel Types

Whether it's paintings, albums, books, or movies, Google follows consistent patterns:

```html
<!-- Any carousel type follows this pattern -->
<div data-attrid="kc:/[type]/...">
  <div> <!-- Variable nesting depth -->
    <div> <!-- Item container -->
      <a href="/search?q=...">Item Name</a>
      ...
      <img src="..." alt="Item Name">
      ...
      <div>
        <div>Extension Data</div>
        <div>More Extension Data</div>
      </div>
    </div>
  </div>
</div>
```

Sometimes the structure varies with nested elements:

```html
<!-- Alternative structure with image inside anchor -->
<div data-attrid="kc:/[type]/...">
  <div>
    <div> <!-- Item container -->
      <a href="/search?q=...">
        <img src="..." alt="Item Name">
        <div>Item Name</div>
      </a>
      <div>Extension Data</div>
    </div>
  </div>
</div>
```

**The core insight**: Google maintains semantic consistency (KC markers, anchor+image patterns) while allowing visual presentation to evolve. The parser leverages the former while being agnostic to the latter.

The `has_required_elements?` method simply checks for the presence of both anchor and image tags anywhere within a div, regardless of nesting:

```ruby
def has_required_elements?(div)
  has_anchor = div.css('a').any?
  has_image = div.css('img').any?
  has_anchor && has_image
end
```

This means both structural variations above are detected as valid item containers. The extraction logic then adapts:
- **Anchor text extraction**: Works whether the anchor contains text directly or wraps other elements
- **Image detection**: Finds images at any nesting level within the container
- **Extension parsing**: Scans all child divs, automatically excluding the identified name

For carousels with significantly different structures (like enriched recommendation lists), the architecture supports **custom extraction approaches**. Each parser can override any method from the base class to handle its specific layout requirements while still benefiting from the shared infrastructure.

### Default Parser Fallback

For unknown carousel types, the system falls back to `DefaultParser`:

```ruby
class DefaultParser < BaseParser
  def initialize_results
    { items: [] }  # Generic structure
  end
  
  def results_key
    :items
  end
end
```

This means **any new Google carousel will be parsed automatically** using the same robust extraction logic, returning data in a generic `{ items: [...] }` format until a specific parser is created.

## Benefits Summary

- **Fast Development**: New carousel types require minimal code
- **Type Safety**: Each parser returns predictable data structure
- **Easy Testing**: Clear interfaces enable comprehensive test coverage
- **Future-Proof**: Architecture accommodates Google's carousel evolution
- **Code Reuse**: Common functionality shared across all parsers
- **Clean Separation**: HTML parsing separated from business logic  
