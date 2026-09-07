Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :weather_alerts, only: %i[index show]
  # index acepta lat y lng y redirige a la zona que contiene el punto.
  resources :weather_zones, only: %i[index show]
  # index es el buscador por nombre.
  resources :municipalities, only: %i[index show]

  root "weather_alerts#index"
end
