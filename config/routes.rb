# frozen_string_literal: true

Rails.application.routes.draw do
  # Root path
  root "dashboard#index"

  # Dashboard routes
  get "/dashboard", to: "dashboard#index", as: :dashboard
  post "/dashboard/ingest", to: "dashboard#ingest", as: :dashboard_ingest
  get "/dashboard/seed", to: "dashboard#seed", as: :dashboard_seed
  get "/dashboard/:id", to: "dashboard#show", as: :dashboard_agency

  # API routes
  namespace :api do
    resources :agencies, only: [:index, :show]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA files
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
