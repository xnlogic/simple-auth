Rails.application.routes.draw do
  root to: 'visitors#index'
  devise_for :users, :controllers => {sessions: 'sessions', registrations: 'registrations'}
  as :user do
    get '/login' => 'sessions#new', as: 'login'
    post '/sessions', to: 'sessions#create', as: 'sessions'
    delete '/sessions/logout', to: 'sessions#destroy', as: 'logout'
  end
  resources :users do |u|
    get 'welcome', on: :member
  end
end
