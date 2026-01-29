class Anga < ApplicationRecord
  before_create :generate_uuid

  belongs_to :user
  has_one_attached :file
  has_one :bookmark, dependent: :destroy

  validates :filename, presence: true
  validates :filename, uniqueness: { scope: :user_id }
  validates :filename, format: {
    with: /\A\d{4}-\d{2}-\d{2}T\d{6}(_\d{9})?.*\z/,
    message: "must start with YYYY-mm-ddTHHMMSS or YYYY-mm-ddTHHMMSS_SSSSSSSSS format"
  }

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end
end
