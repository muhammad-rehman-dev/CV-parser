require "net/http"

# Posts a "candidate_onboarding_completed" event when CANDIDATE_ONBOARDING_WEBHOOK_URL is set.
class DeliverOnboardingWebhookJob < ApplicationJob
  queue_as :default

  def perform(profile_id)
    url = ENV["CANDIDATE_ONBOARDING_WEBHOOK_URL"].presence
    return if url.nil?

    profile = CandidateProfile.find_by(id: profile_id)
    return if profile.nil?

    uri = URI.parse(url)
    request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    request.body = payload(profile).to_json

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 5) do |http|
      http.request(request)
    end
  end

  private

  def payload(profile)
    {
      event: "candidate_onboarding_completed",
      occurred_at: Time.current.iso8601,
      candidate: {
        id: profile.id,
        name: profile.full_name,
        email: profile.email,
        city: profile.city,
        job_function: profile.job_function&.name,
        years_of_experience: profile.years_of_experience
      }
    }
  end
end
