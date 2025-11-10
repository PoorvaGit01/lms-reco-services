Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    resources :courses, only: [:index, :show, :create, :update, :destroy]
    resources :lessons, only: [:index, :show, :create, :update, :destroy] do
      member do
        post :complete
      end
    end
    resources :users, only: [] do
      member do
        get :stats
      end
    end
  end
end
