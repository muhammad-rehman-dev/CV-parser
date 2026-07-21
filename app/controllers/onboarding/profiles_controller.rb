module Onboarding
  # Step 2: review and complete the CV-prefilled profile.
  class ProfilesController < BaseController
    include ConsentVerification

    def edit
      build_missing_nested_records
    end

    def update
      completion = Onboarding::ProfileCompletion.new(
        candidate_profile,
        attributes: profile_params,
        consent: consent_given?,
        selected_skill_ids: params.dig(:candidate_profile, :skill_ids),
        kept_suggestion_ids: params[:kept_candidate_skill_ids]
      )

      if completion.call
        Onboarding::CompletionNotifier.new(candidate_profile).call
        redirect_to onboarding_done_path, notice: "Your profile has been saved."
      else
        build_missing_nested_records
        flash.now[:alert] = "Please correct the highlighted fields."
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def profile_params
      params.require(:candidate_profile).permit(
        :first_name, :last_name, :email, :phone_number, :city, :country,
        :job_function_id, :max_travel_time, :search_status, :reason_for_looking,
        :desired_gross_salary, :desired_percentage, :average_daily_revenue,
        :big_registration_status, :big_number, :years_of_experience,
        :available_from, :notice_period,
        :professional_summary, :motivation, :internal_notes,
        transport_types: [], available_working_days: [],
        region_ids: [], employment_type_ids: [],
        educations_attributes: %i[id institution study city_and_country level start_date end_date _destroy],
        work_experiences_attributes: %i[id job_title company_name responsibilities start_date end_date current_job _destroy],
        candidate_languages_attributes: %i[id language_id level _destroy]
      )
    end

    # Show at least one blank education/work/language row.
    def build_missing_nested_records
      candidate_profile.educations.build if candidate_profile.educations.empty?
      candidate_profile.work_experiences.build if candidate_profile.work_experiences.empty?
      candidate_profile.candidate_languages.build if candidate_profile.candidate_languages.empty?
    end
  end
end
