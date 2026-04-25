Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :books
  resources :recommenders
  resources :recommendations, only: %i[index show update destroy]

  get "up" => "rails/health#show", :as => :rails_health_check

  root "home#index"
end
