require "test_helper"

class CandidateProfileTest < ActiveSupport::TestCase
  setup do
    create_reference_data!
    @user = create_candidate
  end

  # A freshly created (empty) profile must save so the upload step can create one.
  test "empty profile is valid in the default context" do
    profile = @user.build_candidate_profile
    assert profile.valid?
  end

  test "a fully completed dentist profile is valid in the :complete context" do
    profile = complete_dentist_profile
    assert profile.valid?(:complete), profile.errors.full_messages.to_sentence
  end

  test "required personal fields are enforced on completion" do
    profile = complete_dentist_profile
    profile.first_name = nil
    assert_not profile.valid?(:complete)
    assert_includes profile.errors.attribute_names, :first_name
  end

  test "employed candidates must provide a salary" do
    profile = complete_dentist_profile
    profile.desired_gross_salary = nil
    assert_not profile.valid?(:complete)
    assert_includes profile.errors.attribute_names, :desired_gross_salary
  end

  test "self-employed candidates must provide a percentage between 0 and 100" do
    profile = complete_dentist_profile
    profile.employment_types = [@freelance]
    profile.desired_gross_salary = nil
    profile.desired_percentage = 150
    assert_not profile.valid?(:complete)
    assert_includes profile.errors.attribute_names, :desired_percentage
  end

  test "dentists must provide BIG registration status and number when registered" do
    profile = complete_dentist_profile
    profile.big_registration_status = :big_registered
    profile.big_number = nil
    assert_not profile.valid?(:complete)
    assert_includes profile.errors.attribute_names, :big_number
  end

  test "assistants do not require BIG registration" do
    profile = complete_dentist_profile
    profile.job_function = @assistant
    profile.big_registration_status = nil
    profile.big_number = nil
    profile.average_daily_revenue = nil # assistant is not revenue based
    assert profile.valid?(:complete), profile.errors.full_messages.to_sentence
  end

  test "invalid phone numbers are rejected on completion" do
    profile = complete_dentist_profile
    profile.phone_number = "not-a-phone"
    assert_not profile.valid?(:complete)
    assert_includes profile.errors.attribute_names, :phone_number
  end

  private

  def complete_dentist_profile
    profile = @user.create_candidate_profile!(
      first_name: "Jan", last_name: "de Vries", email: "jan@example.com",
      phone_number: "+31612345678", city: "Utrecht", job_function: @dentist,
      max_travel_time: 30, years_of_experience: 5, search_status: :active,
      available_from: Date.current, available_working_days: %w[monday tuesday],
      big_registration_status: :big_registered, big_number: "12345678901",
      desired_gross_salary: 4000, average_daily_revenue: 750
    )
    profile.regions = [@region]
    profile.employment_types = [@employed]
    profile.candidate_languages.create!(language: @language, level: "native")
    profile
  end
end
