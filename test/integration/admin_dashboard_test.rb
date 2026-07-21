require "test_helper"

class AdminDashboardTest < ActionDispatch::IntegrationTest
  setup do
    create_reference_data!
    @admin = AdminUser.create!(email: "admin-#{SecureRandom.hex(4)}@example.com", password: "password")
    sign_in @admin, scope: :admin_user

    @profile = create_candidate.create_candidate_profile!(
      first_name: "Sophie", last_name: "Bakker", email: "sophie@example.nl",
      city: "Utrecht", job_function: @dentist
    )
    @profile.regions = [@region]
    @profile.employment_types = [@employed]
    @profile.candidate_languages.create!(language: @language, level: "native")
    @profile.candidate_skills.create!(skill: @skill, source: :cv_matched)
    @profile.educations.create!(study: "Mondzorgkunde")
    @profile.work_experiences.create!(job_title: "Hygienist", company_name: "Clinic")
  end

  test "candidate profiles index renders" do
    get admin_candidate_profiles_path
    assert_response :success
  end

  test "candidate profile show renders with all sections" do
    get admin_candidate_profile_path(@profile)
    assert_response :success
    assert_select "body", /Sophie/
  end

  test "configuration resources render" do
    [admin_settings_path, admin_job_functions_path, admin_regions_path,
     admin_employment_types_path, admin_languages_path, admin_skills_path].each do |path|
      get path
      assert_response :success, "expected #{path} to render"
    end
  end
end
