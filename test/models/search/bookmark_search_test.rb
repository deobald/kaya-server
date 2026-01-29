require "test_helper"

class Search::BookmarkSearchTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  test "returns no match when bookmark has no cached content" do
    anga = create(:anga, user: @user, filename: "2024-01-01T120000-example.url")
    create(:bookmark, anga: anga, url: "https://example.com")

    search = Search::BookmarkSearch.new(anga)
    result = search.search("testing")

    assert_not result.match?
    assert_equal 0.0, result.score
  end

  test "extracts and searches text content from cached HTML" do
    anga = create(:anga, user: @user, filename: "2024-01-01T120000-example.url")
    bookmark = create(:bookmark, anga: anga, url: "https://example.com", cached_at: Time.current)
    bookmark.html_file.attach(
      io: StringIO.new("<html><body><h1>Welcome</h1><p>This is a testing page with important content.</p></body></html>"),
      filename: "index.html",
      content_type: "text/html"
    )

    search = Search::BookmarkSearch.new(anga)
    result = search.search("testing")

    assert result.match?
    assert result.score >= 0.75
    assert_equal "testing", result.matched_text
  end

  test "removes script tags from searchable content" do
    anga = create(:anga, user: @user, filename: "2024-01-01T120000-example.url")
    bookmark = create(:bookmark, anga: anga, url: "https://example.com", cached_at: Time.current)
    bookmark.html_file.attach(
      io: StringIO.new("<html><body><script>var secretword = 'findme';</script><p>Regular content here.</p></body></html>"),
      filename: "index.html",
      content_type: "text/html"
    )

    search = Search::BookmarkSearch.new(anga)
    result = search.search("secretword")

    assert_not result.match?
  end

  test "removes style tags from searchable content" do
    anga = create(:anga, user: @user, filename: "2024-01-01T120000-example.url")
    bookmark = create(:bookmark, anga: anga, url: "https://example.com", cached_at: Time.current)
    bookmark.html_file.attach(
      io: StringIO.new("<html><head><style>.mystyle { color: red; }</style></head><body><p>Visible text.</p></body></html>"),
      filename: "index.html",
      content_type: "text/html"
    )

    search = Search::BookmarkSearch.new(anga)
    result = search.search("mystyle")

    assert_not result.match?
  end

  test "removes noscript tags from searchable content" do
    anga = create(:anga, user: @user, filename: "2024-01-01T120000-example.url")
    bookmark = create(:bookmark, anga: anga, url: "https://example.com", cached_at: Time.current)
    bookmark.html_file.attach(
      io: StringIO.new("<html><body><noscript>JavaScript disabled message</noscript><p>Main content.</p></body></html>"),
      filename: "index.html",
      content_type: "text/html"
    )

    search = Search::BookmarkSearch.new(anga)
    # "disabled" is in noscript, should not match
    result = search.search("disabled")

    assert_not result.match?
  end

  test "searches multi-word phrases" do
    anga = create(:anga, user: @user, filename: "2024-01-01T120000-example.url")
    bookmark = create(:bookmark, anga: anga, url: "https://example.com", cached_at: Time.current)
    bookmark.html_file.attach(
      io: StringIO.new("<html><body><p>The quick brown fox jumps over the lazy dog.</p></body></html>"),
      filename: "index.html",
      content_type: "text/html"
    )

    search = Search::BookmarkSearch.new(anga)
    result = search.search("quick brown")

    assert result.match?
    assert result.score >= 0.75
  end

  test "handles HTML with complex nested structure" do
    anga = create(:anga, user: @user, filename: "2024-01-01T120000-example.url")
    bookmark = create(:bookmark, anga: anga, url: "https://example.com", cached_at: Time.current)
    html = <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <title>Test Page</title>
          <style>.hidden { display: none; }</style>
          <script>console.log('test');</script>
        </head>
        <body>
          <header><nav>Navigation</nav></header>
          <main>
            <article>
              <h1>Article Title</h1>
              <p>This article contains <strong>important</strong> information about <em>programming</em>.</p>
            </article>
          </main>
          <footer>Copyright 2024</footer>
        </body>
      </html>
    HTML
    bookmark.html_file.attach(
      io: StringIO.new(html),
      filename: "index.html",
      content_type: "text/html"
    )

    search = Search::BookmarkSearch.new(anga)

    # Should find visible text
    result = search.search("programming")
    assert result.match?

    # Should not find script content
    result = search.search("console")
    assert_not result.match?
  end

  test "returns nil content gracefully when bookmark not cached" do
    anga = create(:anga, user: @user, filename: "2024-01-01T120000-example.url")
    create(:bookmark, anga: anga, url: "https://example.com")

    search = Search::BookmarkSearch.new(anga)
    result = search.search("anything")

    assert_not result.match?
    assert_equal 0.0, result.score
  end

  test "returns nil content gracefully when no bookmark exists" do
    anga = create(:anga, user: @user, filename: "2024-01-01T120000-example.url")
    # No bookmark created

    search = Search::BookmarkSearch.new(anga)
    result = search.search("anything")

    assert_not result.match?
    assert_equal 0.0, result.score
  end

  test "matches filename when not a common pattern" do
    anga = create(:anga, user: @user, filename: "2024-01-01T120000-rubyguide.url")
    create(:bookmark, anga: anga, url: "https://example.com")

    search = Search::BookmarkSearch.new(anga)
    result = search.search("rubyguide")

    assert result.match?
    assert_equal anga.filename, result.matched_text
  end

  test "uses fuzzy matching for content" do
    anga = create(:anga, user: @user, filename: "2024-01-01T120000-example.url")
    bookmark = create(:bookmark, anga: anga, url: "https://example.com", cached_at: Time.current)
    bookmark.html_file.attach(
      io: StringIO.new("<html><body><p>Documentation for developers</p></body></html>"),
      filename: "index.html",
      content_type: "text/html"
    )

    search = Search::BookmarkSearch.new(anga)
    # "documntation" is a typo of "documentation" - should still fuzzy match
    result = search.search("documentation")

    assert result.match?
    assert result.score >= 0.75
  end
end
