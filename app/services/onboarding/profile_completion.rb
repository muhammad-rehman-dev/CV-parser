module Onboarding
  # Finalises a candidate profile: applies attributes, enforces consent, runs the
  # :complete validations and reconciles skills in one transaction. Returns a
  # boolean; on failure the profile carries the errors and completed_at is reset.
  class ProfileCompletion
    def initialize(profile, attributes:, consent:, selected_skill_ids:, kept_suggestion_ids:)
      @profile = profile
      @attributes = attributes
      @consent = consent
      @selected_skill_ids = Array(selected_skill_ids).map(&:to_i).reject(&:zero?)
      @kept_suggestion_ids = Array(kept_suggestion_ids).map(&:to_i)
    end

    def call
      unless @consent
        @profile.errors.add(:base, "You must agree to the processing consent before saving.")
        return false
      end

      saved = false

      ActiveRecord::Base.transaction do
        @profile.assign_attributes(@attributes)
        @profile.completed_at ||= Time.current

        if @profile.save(context: :complete)
          sync_known_skills
          sync_cv_suggestions
          saved = true
        else
          raise ActiveRecord::Rollback
        end
      end

      @profile.completed_at = nil unless saved
      saved
    end

    private

    def sync_known_skills
      known = @profile.candidate_skills.where.not(skill_id: nil)
      known.where.not(skill_id: @selected_skill_ids).destroy_all

      existing = @profile.candidate_skills.where.not(skill_id: nil).pluck(:skill_id)
      (@selected_skill_ids - existing).each do |skill_id|
        @profile.candidate_skills.create!(skill_id: skill_id, source: :manual)
      end
    end

    def sync_cv_suggestions
      @profile.candidate_skills.where(skill_id: nil).where.not(id: @kept_suggestion_ids).destroy_all
    end
  end
end
