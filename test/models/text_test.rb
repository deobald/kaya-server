# == Schema Information
#
# Table name: texts
# Database name: primary
#
#  id            :string(36)       not null, primary key
#  extract_error :text
#  extracted_at  :datetime
#  source_type   :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  anga_id       :string(36)       not null
#
# Indexes
#
#  index_texts_on_anga_id  (anga_id) UNIQUE
#
# Foreign Keys
#
#  anga_id  (anga_id => angas.id)
#
require "test_helper"

class TextTest < ActiveSupport::TestCase
  test "requires source_type" do
    text = Text.new(anga: create(:anga))
    assert_not text.valid?
    assert_includes text.errors[:source_type], "can't be blank"
  end

  test "source_type must be bookmark or pdf" do
    text = Text.new(anga: create(:anga), source_type: "invalid")
    assert_not text.valid?
    assert_includes text.errors[:source_type], "is not included in the list"
  end

  test "accepts bookmark source_type" do
    text = create(:text, :bookmark)
    assert text.valid?
    assert_equal "bookmark", text.source_type
  end

  test "accepts pdf source_type" do
    text = create(:text, :pdf)
    assert text.valid?
    assert_equal "pdf", text.source_type
  end

  test "generates uuid on create" do
    text = create(:text)
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, text.id)
  end

  test "extracted? returns false when not extracted" do
    text = create(:text)
    assert_not text.extracted?
  end

  test "extracted? returns true when extracted" do
    text = create(:text, :extracted)
    assert text.extracted?
  end

  test "extract_failed? returns true when error present" do
    text = create(:text, :failed)
    assert text.extract_failed?
  end

  test "extract_failed? returns false when no error" do
    text = create(:text)
    assert_not text.extract_failed?
  end

  test "extract_pending? returns true when neither extracted nor failed" do
    text = create(:text)
    assert text.extract_pending?
  end

  test "extract_pending? returns false when extracted" do
    text = create(:text, :extracted)
    assert_not text.extract_pending?
  end

  test "extract_pending? returns false when failed" do
    text = create(:text, :failed)
    assert_not text.extract_pending?
  end

  test "text_filename returns .md for bookmarks" do
    anga = create(:anga, :bookmark, filename: "2024-01-01T120000-example.url")
    text = create(:text, :bookmark, anga: anga)
    assert_equal "2024-01-01T120000-example.md", text.text_filename
  end

  test "text_filename returns .txt for pdfs" do
    anga = create(:anga, :pdf, filename: "2024-01-01T120000-document.pdf")
    text = create(:text, :pdf, anga: anga)
    assert_equal "2024-01-01T120000-document.txt", text.text_filename
  end

  test "belongs to anga" do
    anga = create(:anga)
    text = create(:text, anga: anga)
    assert_equal anga, text.anga
  end

  test "destroying anga destroys text" do
    anga = create(:anga)
    create(:text, anga: anga)
    assert_difference("Text.count", -1) do
      anga.destroy
    end
  end
end
