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
class Text < ApplicationRecord
  before_create :generate_uuid

  belongs_to :anga

  has_one_attached :file

  validates :source_type, presence: true, inclusion: { in: %w[bookmark pdf] }

  def extracted?
    extracted_at.present? && file.attached?
  end

  def extract_failed?
    extract_error.present?
  end

  def extract_pending?
    !extracted? && !extract_failed?
  end

  # Returns the text filename for the API
  # Bookmarks: {anga_filename}.md
  # PDFs: {anga_filename}.txt
  def text_filename
    base = anga.filename
    case source_type
    when "bookmark"
      "#{File.basename(base, '.*')}.md"
    when "pdf"
      "#{File.basename(base, '.*')}.txt"
    end
  end

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end
end
