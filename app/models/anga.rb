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
class Anga < ApplicationRecord
  before_create :generate_uuid
  after_create_commit :setup_bookmark, if: :bookmark_file?
  after_create_commit :setup_pdf_text, if: :pdf_file?

  belongs_to :user
  has_one_attached :file
  has_one :bookmark, dependent: :destroy
  has_one :text, dependent: :destroy
  has_many :metas, dependent: :nullify

  validates :filename, presence: true
  validates :filename, uniqueness: { scope: :user_id }
  validates :filename, format: {
    with: /\A\d{4}-\d{2}-\d{2}T\d{6}(_\d{9})?.*\z/,
    message: "must start with YYYY-mm-ddTHHMMSS or YYYY-mm-ddTHHMMSS_SSSSSSSSS format"
  }

  def bookmark_file?
    Files::FileType.new(filename).bookmark?
  end

  def pdf_file?
    Files::FileType.new(filename).pdf?
  end

  # Returns the original URL for bookmark files
  def bookmark_url
    return nil unless bookmark_file?
    return bookmark.url if bookmark&.url.present?
    extract_url_from_content
  end

  def extract_url_from_content
    return nil unless file.attached?
    content = file.download.force_encoding("UTF-8")
    content[/URL=(.+)/, 1]&.strip
  rescue => e
    Rails.logger.warn "🟠 WARN: Failed to extract URL from #{filename}: #{e.message}"
    nil
  end

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end

  def setup_bookmark
    SetupBookmarkJob.perform_later(id)
  end

  def setup_pdf_text
    ExtractPlaintextPdfJob.perform_later(id)
  end
end
