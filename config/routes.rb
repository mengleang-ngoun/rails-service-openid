Rails.application.routes.draw do
  resources :posts
  get 'home/index'

  get 'login', to: 'sessions#new', as: 'new_session'
  get 'signin-oidc', to: 'sessions#callback', as: 'session_callback'
  get 'logout', to: 'sessions#destroy', as: 'destroy_session'

  get 'metadata', to: 'sessions#metadata', as: 'metadata'
  get 'login-saml', to: 'sessions#new_saml', as: 'new_saml_session'
  post 'saml_callback', to: "sessions#saml_callback"

  get 'dashboard', to: 'dashboard#index'

  root 'home#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
