Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :movie_queues, only: [:show, :create, :update, :destroy]

end

