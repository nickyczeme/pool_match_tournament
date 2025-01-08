Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  resources :players, only: [:index, :create, :show, :update, :destroy]
  resources :matches, only: [:index, :create, :show, :update, :destroy]
end
