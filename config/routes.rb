Rails.application.routes.draw do
  root to: 'visitors#index'
  devise_for :users, :controllers => {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  get '/users/search_ldap_users' => 'users#search_ldap', as: 'search_ldap_users'
  get '/users/new_ldap' => 'users#new_ldap', as: 'new_ldap_user'
  resources :users do |u|
    get 'welcome', on: :collection
  end

  post '/users/create_user' => 'users#create', as: 'create_user'
  get '/users/:id/disable_user' => 'users#disable', as: 'disable_user'

  devise_scope :user do
    get '/login' => 'users/sessions#new', as: 'login'
    post '/sessions', to: 'users/sessions#create', as: 'sessions'
    delete '/sessions/logout', to: 'users/sessions#destroy', as: 'logout'
  end
end
