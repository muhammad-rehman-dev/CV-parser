Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :onboarding do
    get "/", to: "steps#show", as: :root
    get "done", to: "steps#done", as: :done

    resource :cv_upload, only: %i[new create]

    resources :documents, only: %i[show] do
      get :status, on: :member
    end

    resource :profile, only: %i[edit update]
  end

  authenticated :user do
    root to: "onboarding/steps#show", as: :authenticated_root
  end
  root to: "home#show"
end
