class RecruitmentMailer < ApplicationMailer
  # Sent when a candidate finishes onboarding.
  def candidate_completed(profile)
    @profile = profile
    @job_function = profile.job_function&.name

    mail(
      to: ENV.fetch("RECRUITMENT_TEAM_EMAIL", "recruitment@example.com"),
      subject: "New candidate profile: #{profile.full_name.presence || profile.email}"
    )
  end
end
