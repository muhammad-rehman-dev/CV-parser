module Onboarding
  # Shared base for onboarding controllers: requires a signed-in candidate.
  class BaseController < ApplicationController
    before_action :authenticate_user!

    private

    def candidate_profile
      @candidate_profile ||= current_user.candidate_profile!
    end
    helper_method :candidate_profile
  end
end
