Rails.application.routes.draw do
  # First-run setup (only accessible when no users exist)
  constraints(->(request) { User.count.zero? }) do
    get "setup", to: "setup#new"
    post "setup", to: "setup#create"
  end

  # Authentication
  resource :session
  resources :passwords, param: :token

  # 2FA
  resource :two_factor, only: %i[new create destroy], controller: "two_factor"
  resource :two_factor_session, only: %i[new create]

  # WebAuthn / Passkeys
  namespace :webauthn do
    resources :credentials, only: %i[new create destroy]
    resource :session, only: %i[new create]
  end

  # Registration via invitation
  get "register/:code", to: "registrations#new", as: :register
  post "register/:code", to: "registrations#create"

  # Profile
  resource :profile, only: %i[show update destroy]

  # File uploads (authenticated)
  resources :uploads, only: %i[new create show destroy]

  # Public download (no auth required)
  get "d/:hash", to: "downloads#show", as: :download
  post "d/:hash/file", to: "downloads#file", as: :download_file
  get "d/:hash/preview", to: "downloads#preview", as: :download_preview

  # Admin panel
  namespace :admin do
    resources :users do
      member do
        post :ban
        post :unban
        post :reset_password
      end
    end
    resources :invitations, only: %i[index new create destroy]
    resources :shared_files, only: %i[index show destroy]
    resources :allowed_mime_types, only: %i[index new create destroy]

    root to: "users#index"
  end

  # Terms of Service
  get "terms", to: "terms#show"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root
  root "uploads#new"

  # Catch-all for non-existent routes
  match "*unmatched", to: "application#route_not_found", via: :all, constraints: ->(req) { !req.path.start_with?("/rails/") }
end
