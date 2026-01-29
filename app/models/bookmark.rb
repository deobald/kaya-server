class Bookmark < ApplicationRecord
  before_create :generate_uuid

  belongs_to :anga

  # Main HTML file for the cached page
  has_one_attached :html_file

  # Favicon for the website
  has_one_attached :favicon

  # Associated assets (CSS, JS, images)
  has_many_attached :assets

  validates :url, presence: true

  # Returns the cache directory name (same as anga filename)
  def cache_directory_name
    anga.filename
  end

  # Returns true if the bookmark has been cached
  def cached?
    cached_at.present? && html_file.attached?
  end

  # Returns true if caching failed
  def cache_failed?
    cache_error.present?
  end

  # Returns true if caching is still pending (not cached and no error)
  def cache_pending?
    !cached? && !cache_failed?
  end

  # Returns a list of all cached file names for the API
  def cached_file_list
    files = []
    files << "index.html" if html_file.attached?
    files << "favicon.ico" if favicon.attached?
    assets.each do |asset|
      files << asset.filename.to_s
    end
    files
  end

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end
end
