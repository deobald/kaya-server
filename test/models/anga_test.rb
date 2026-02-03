# == Schema Information
#
# Table name: angas
# Database name: primary
#
#  id         :string(36)       not null, primary key
#  filename   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :string(36)       not null
#
# Indexes
#
#  index_angas_on_user_id               (user_id)
#  index_angas_on_user_id_and_filename  (user_id,filename) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
require "test_helper"

class AngaTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "bookmark_url returns nil for non-bookmark files" do
    anga = build(:anga, :note)
    anga.save!
    assert_nil anga.bookmark_url
  end

  test "bookmark_url extracts URL from .url file content when no bookmark record exists" do
    user = create(:user)
    anga = user.angas.new(filename: "2025-01-30T120000-extract-test.url")
    anga.file.attach(
      io: StringIO.new("[InternetShortcut]\nURL=https://extracted-url.com"),
      filename: "2025-01-30T120000-extract-test.url",
      content_type: "text/plain"
    )
    # Use insert to bypass callbacks and test URL extraction without Bookmark
    anga.id = SecureRandom.uuid
    Anga.insert({
      id: anga.id,
      user_id: user.id,
      filename: anga.filename,
      created_at: Time.current,
      updated_at: Time.current
    })
    anga = Anga.find(anga.id)
    # Reattach file since insert bypasses ActiveStorage
    anga.file.attach(
      io: StringIO.new("[InternetShortcut]\nURL=https://extracted-url.com"),
      filename: "2025-01-30T120000-extract-test.url",
      content_type: "text/plain"
    )

    assert_nil anga.bookmark
    assert_equal "https://extracted-url.com", anga.bookmark_url
  end

  test "bookmark_url returns stored URL from bookmark record when present" do
    user = create(:user)
    anga = user.angas.new(filename: "2025-01-30T120001-stored-test.url")
    anga.file.attach(
      io: StringIO.new("[InternetShortcut]\nURL=https://file-url.com"),
      filename: "2025-01-30T120001-stored-test.url",
      content_type: "text/plain"
    )
    # Bypass callback to create bookmark manually with different URL
    anga.id = SecureRandom.uuid
    Anga.insert({
      id: anga.id,
      user_id: user.id,
      filename: anga.filename,
      created_at: Time.current,
      updated_at: Time.current
    })
    anga = Anga.find(anga.id)
    anga.file.attach(
      io: StringIO.new("[InternetShortcut]\nURL=https://file-url.com"),
      filename: "2025-01-30T120001-stored-test.url",
      content_type: "text/plain"
    )
    anga.create_bookmark!(url: "https://stored-url.com")

    # Should return stored URL, not extracted URL
    assert_equal "https://stored-url.com", anga.bookmark_url
  end

  test "bookmark_file? returns true for .url files" do
    anga = build(:anga, :bookmark)
    assert anga.bookmark_file?
  end

  test "bookmark_file? returns false for non-.url files" do
    anga = build(:anga, :note)
    assert_not anga.bookmark_file?
  end

  test "setup_bookmark enqueues SetupBookmarkJob" do
    user = create(:user)
    anga = user.angas.new(filename: "2025-01-30T120002-setup-test.url")
    anga.file.attach(
      io: StringIO.new("[InternetShortcut]\nURL=https://setup-test.com"),
      filename: "2025-01-30T120002-setup-test.url",
      content_type: "text/plain"
    )
    anga.id = SecureRandom.uuid
    Anga.insert({
      id: anga.id,
      user_id: user.id,
      filename: anga.filename,
      created_at: Time.current,
      updated_at: Time.current
    })
    anga = Anga.find(anga.id)

    assert_enqueued_with(job: SetupBookmarkJob, args: [ anga.id ]) do
      anga.send(:setup_bookmark)
    end
  end

  test "does not create bookmark for non-.url files" do
    anga = build(:anga, :note)
    anga.save!
    assert_nil anga.bookmark
  end
end
