ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Creates the minimal reference data most tests need and exposes it via
    # instance variables (@dentist, @assistant, @region, ...).
    def create_reference_data!
      @dentist = JobFunction.create!(name: "General dentist", slug: "general_dentist",
                                     requires_big_registration: true, revenue_based: true)
      @assistant = JobFunction.create!(name: "Dental assistant", slug: "dental_assistant")
      @region = Region.create!(name: "Utrecht")
      @employed = EmploymentType.create!(name: "Employed", slug: "employed", category: "employed")
      @freelance = EmploymentType.create!(name: "Freelance", slug: "freelance", category: "self_employed")
      @language = Language.create!(name: "Dutch")
      @skill = Skill.create!(name: "Endodontics", job_function: @dentist)
    end

    def create_candidate(email: "candidate-#{SecureRandom.hex(4)}@example.com")
      User.create!(email: email, password: "password", password_confirmation: "password")
    end
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
