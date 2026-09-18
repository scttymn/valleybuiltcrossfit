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

  get "up" => "rails/health#show", as: :rails_health_check
  get "favicon.svg" => "icons#favicon", as: :favicon, format: false
end
