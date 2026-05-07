Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  namespace :books do
    resource :search, only: :show
    resource :import, only: %i[new create]
    resource :import_template, only: :show
  end
  resources :books
  get "insights", to: "insights#index", as: :insights
  resources :recommenders
  resources :recommendations, only: %i[index new create show update destroy]
  resources :preferences, only: %i[index destroy]
  resources :friendships, only: %i[index create update destroy]
  resources :friend_libraries, only: :show, param: :user_id

  get "book_cover" => "book_covers#show", :as => :book_cover

  get "llm/question", to: "llm#question", as: :llm_question
  get "llm/recommend", to: "llm#recommend", as: :llm_recommend
  get "llm/book_chat", to: "llm#book_chat", as: :llm_book_chat

  get "up" => "rails/health#show", :as => :rails_health_check

  root "home#index"
end
