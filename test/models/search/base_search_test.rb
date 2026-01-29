require "test_helper"

# Tests for BaseSearch functionality, tested via GenericFileSearch
class Search::BaseSearchTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  test "matches word in middle of hyphenated filename" do
    anga = create(:anga, user: @user, filename: "2026-01-28T205243-three-button-mooze.png")

    search = Search::GenericFileSearch.new(anga)
    result = search.search("button")

    assert result.match?, "Expected 'button' to match filename 'three-button-mooze'"
    assert_equal 1.0, result.score
    assert_equal anga.filename, result.matched_text
  end

  test "matches first word in hyphenated filename" do
    anga = create(:anga, user: @user, filename: "2026-01-28T205243-three-button-mooze.png")

    search = Search::GenericFileSearch.new(anga)
    result = search.search("three")

    assert result.match?
    assert_equal 1.0, result.score
  end

  test "matches last word in hyphenated filename" do
    anga = create(:anga, user: @user, filename: "2026-01-28T205243-three-button-mooze.png")

    search = Search::GenericFileSearch.new(anga)
    result = search.search("mooze")

    assert result.match?
    assert_equal 1.0, result.score
  end

  test "fuzzy matches words in hyphenated filename" do
    anga = create(:anga, user: @user, filename: "2026-01-28T205243-documentation-guide.png")

    search = Search::GenericFileSearch.new(anga)
    # "documntation" is close to "documentation"
    result = search.search("documentation")

    assert result.match?
    assert result.score >= 0.75
  end

  test "does not match unrelated words" do
    anga = create(:anga, user: @user, filename: "2026-01-28T205243-three-button-mooze.png")

    search = Search::GenericFileSearch.new(anga)
    result = search.search("elephant")

    assert_not result.match?
  end
end
