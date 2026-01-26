Rails.application.routes.draw do
  # Authentication
  resource :session
  resource :registration, only: [ :new, :create ]
  resources :passwords, param: :token

  # Account management
  resource :account, only: [ :show, :update ] do
    delete "identities/:identity_id", to: "accounts#destroy_identity", as: :identity
    patch "avatar", to: "accounts#update_avatar"
  end

  # OmniAuth routes - support both GET and POST callbacks
  # (Google uses GET, some providers use POST)
  get "/auth/:provider/callback", to: "omniauth_callbacks#create"
  post "/auth/:provider/callback", to: "omniauth_callbacks#create"
  get "/auth/failure", to: "omniauth_callbacks#failure"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Homepage
  root "pages#home"
end
