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
    get "site/edit", to: redirect("/admin/site/contact/edit")
    resources :site_sections, path: "site", param: :section, only: %i[edit update], controller: "sites"
    resource :announcement, only: %i[edit update]
    namespace :settings do
      resource :theme, only: %i[edit update] do
        get :preview
      end
      resource :photos, only: %i[edit update]
      resource :pushpress, only: %i[edit update], controller: "pushpress"
    end
    get "settings", to: redirect("/admin/settings/theme/edit")
    get "settings/edit", to: redirect("/admin/settings/theme/edit")
    resources :pillars, :programs, :steps, :membership_options, :staff_members, :faqs, :workouts, except: :show
    resources :leads, only: %i[index show destroy]
    resources :users, except: :show
    post "schedule/refresh" => "dashboard#refresh_schedule", as: :refresh_schedule
  end

  # Error pages, rendered in the theme (app/controllers/errors_controller.rb).
  # ActionDispatch retries the failed request against these paths.
  %w[404 422 500].each { |code| match "/#{code}" => "errors#show", via: :all, status: code }

  get "up" => "rails/health#show", as: :rails_health_check
  get "favicon.svg" => "icons#favicon", as: :favicon, format: false
  # The web app manifest (app/views/pwa): lets the site be installed, with its
  # home-screen name and icon.
  # No service worker: the site sends no push notifications and works online only.
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
