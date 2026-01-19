class OmniauthCallbacksController < ApplicationController
  skip_forgery_protection only: :create
  allow_unauthenticated_access only: :create

  def create
    auth = request.env['omniauth.auth']

    begin
      user = User.from_omniauth(auth)

      # Create a new session for the user
      session = user.sessions.create!(
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )

      # Set the session cookie
      cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }

      redirect_to root_path, notice: "Successfully signed in with #{auth.provider.titleize}!"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_session_path, alert: "Authentication failed: #{e.message}"
    end
  end

  def failure
    redirect_to new_session_path, alert: "Authentication failed: #{params[:message]}"
  end
end
