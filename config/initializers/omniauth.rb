Rails.application.config.middleware.use OmniAuth::Builder do
  # Google OAuth2
  provider :google_oauth2,
    ENV['GOOGLE_CLIENT_ID'],
    ENV['GOOGLE_CLIENT_SECRET'],
    {
      scope: 'email,profile',
      prompt: 'select_account',
      image_aspect_ratio: 'square',
      image_size: 120
    }

  # Apple Sign In
  provider :apple,
    ENV['APPLE_CLIENT_ID'],
    '',
    {
      scope: 'email name',
      team_id: ENV['APPLE_TEAM_ID'],
      key_id: ENV['APPLE_KEY_ID'],
      pem: ENV['APPLE_PRIVATE_KEY']
    }

  # Microsoft OAuth2
  provider :microsoft_graph,
    ENV['MICROSOFT_CLIENT_ID'],
    ENV['MICROSOFT_CLIENT_SECRET'],
    {
      scope: 'openid email profile'
    }
end

# Configure OmniAuth for Rails CSRF protection
OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.silence_get_warning = true
