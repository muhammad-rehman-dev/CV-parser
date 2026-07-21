class HomeController < ApplicationController
  def show
    redirect_to onboarding_root_path if user_signed_in?
  end
end
