module Onboarding
  # Post-completion follow-up: emails the recruitment team and (optionally) fires the webhook.
  class CompletionNotifier
    def initialize(profile)
      @profile = profile
    end

    def call
      RecruitmentMailer.candidate_completed(@profile).deliver_later
      enqueue_webhook
    end

    private

    def enqueue_webhook
      return if ENV["CANDIDATE_ONBOARDING_WEBHOOK_URL"].blank?

      DeliverOnboardingWebhookJob.perform_later(@profile.id)
    end
  end
end
