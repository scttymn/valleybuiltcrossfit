Rails.application.routes.draw do
  root "pages#home"
  get "schedule" => "schedules#show", as: :schedule
  resources :leads, only: :create

  get "login" => "sessions#new", as: :login
  post "login" => "sessions#create"
  delete "logout" => "sessions#destroy", as: :logout
  get "logout" => "sessions#destroy"
  resources :passwords, param: :token

  namespace :admin do
    root "dashboard#show"
    resource :site, only: %i[edit update]
    resource :announcement, only: %i[edit update]
    resource :settings, only: %i[edit update] do
      get :theme_preview
    end
    resources :pillars, :programs, :steps, :membership_options, :staff_members, :faqs, :workouts, except: :show
    resources :leads, only: %i[index show destroy]
    resources :users, except: :show
    post "schedule/refresh" => "dashboard#refresh_schedule", as: :refresh_schedule
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
