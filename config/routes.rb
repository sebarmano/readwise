Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :books
  namespace :books do
    resource :search, only: :show
    resource :import, only: %i[new create]
    resource :import_template, only: :show
  end
  resources :recommenders
  resources :recommendations, only: %i[index show update destroy]

  get "up" => "rails/health#show", :as => :rails_health_check

  root "home#index"
end
