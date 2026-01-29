Rails.application.routes.draw do
  # API
  namespace :api do
    namespace :v1 do
      get "handshake", to: "handshake#show"
      scope ":user_email", constraints: { user_email: /[^\/]+/ } do
        resources :anga, only: [ :index ], controller: "anga", as: "user_anga"
        get "anga/:filename", to: "anga#show", as: "user_anga_file", constraints: { filename: /[^\/]+/ }
        post "anga/:filename", to: "anga#create", constraints: { filename: /[^\/]+/ }

        # Cache API for bookmark webpage caching
        get "cache", to: "cache#index", as: "cache"
        get "cache/:bookmark", to: "cache#show", as: "cache_bookmark", constraints: { bookmark: /[^\/]+/ }
        get "cache/:bookmark/:filename", to: "cache#file", as: "cache_file", constraints: { bookmark: /[^\/]+/, filename: /[^\/]+/ }
      end
    end
  end

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

  # App routes (authenticated)
  scope "/app", as: "app" do
    get "/", to: redirect("/app/everything")
    get "everything", to: "everything#index"
    get "anga/:id/preview", to: "anga#preview", as: "anga_preview"
    get "anga/:id/cache_status", to: "anga#cache_status", as: "anga_cache_status"
    get "anga/:id/cache/:filename", to: "anga#cache_file", as: "anga_cache_file", constraints: { filename: /[^\/]+/ }
    post "anga", to: "anga#create", as: "anga_create"
  end

  # Homepage
  root "pages#home"
end
