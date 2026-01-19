class Identity < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :provider, inclusion: { in: %w[google_oauth2 apple microsoft_graph] }
end
