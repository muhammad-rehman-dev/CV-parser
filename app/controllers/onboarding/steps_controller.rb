module Onboarding
  # Dispatches the candidate to the right onboarding step for their progress.
  class StepsController < BaseController
    def show
      document = candidate_profile.latest_cv

      if candidate_profile.completed?
        redirect_to onboarding_done_path
      elsif document&.parsing_finished?
        redirect_to edit_onboarding_profile_path
      elsif document.present?
        redirect_to status_onboarding_document_path(document)
      else
        redirect_to new_onboarding_cv_upload_path
      end
    end

    def done
      redirect_to new_onboarding_cv_upload_path unless candidate_profile.completed?
    end
  end
end
