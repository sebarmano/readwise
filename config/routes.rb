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

  get "llm/question", to: "llm#question", as: :llm_question
  get "llm/recommend", to: "llm#recommend", as: :llm_recommend

  get "up" => "rails/health#show", :as => :rails_health_check

  root "home#index"
end
