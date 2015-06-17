Rails.application.routes.draw do
  root to: 'visitors#index'
  devise_for :users, :controllers => {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  } do
    get '/login' => 'users/sessions#new', as: 'login'
    post '/sessions', to: 'users/sessions#create', as: 'sessions'
    delete '/sessions/logout', to: 'users/sessions#destroy', as: 'logout'
  end
  resources :users do |u|
    get 'welcome', on: :member
  end
end
