class User < ApplicationRecord
  # Generate UUID for new records
  before_create :generate_uuid

  has_secure_password validations: false
  has_many :sessions, dependent: :destroy
  has_many :identities, dependent: :destroy
  has_one_attached :avatar

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }, if: :password_required?
  validates :password, confirmation: true, if: -> { password.present? }
  validates :password_confirmation, presence: true, if: -> { password.present? && password_confirmation_required? }

  attr_accessor :password_confirmation_required

  def password_confirmation_required?
    password_confirmation_required
  end

  def password_required?
    # Password is required if no password_digest exists (new user) and no OAuth identity
    password_digest.nil? || password.present?
  end

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end

  # Find or create user from OAuth authentication data
  def self.from_omniauth(auth)
    # Find existing identity
    identity = Identity.find_by(provider: auth.provider, uid: auth.uid)

    if identity
      # Return existing user
      identity.user
    else
      # Find user by email or create new one
      user = User.find_by(email_address: auth.info.email)

      unless user
        user = User.create!(
          email_address: auth.info.email,
          password: SecureRandom.hex(32), # Random password for OAuth users
          incidental_password: true
        )
      end

      # Create identity for this OAuth provider
      user.identities.create!(
        provider: auth.provider,
        uid: auth.uid
      )

      user
    end
  end
end
