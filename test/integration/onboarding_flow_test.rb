require "test_helper"

class OnboardingFlowTest < ActionDispatch::IntegrationTest
  setup do
    create_reference_data!
    @user = create_candidate
    sign_in @user
  end

  test "root sends a new candidate to the CV upload step" do
    get onboarding_root_path
    assert_redirected_to new_onboarding_cv_upload_path
  end

  test "uploading a CV stores it privately and enqueues parsing" do
    file = fixture_file_upload("sample_cv.pdf", "application/pdf")

    assert_difference -> { CandidateDocument.count } => 1 do
      assert_enqueued_with(job: ParseCandidateCvJob) do
        post onboarding_cv_upload_path, params: { candidate_document: { file: file }, consent: "1" }
      end
    end

    document = @user.candidate_profile.candidate_documents.last
    assert document.file.attached?
    assert document.pending?
    assert_redirected_to status_onboarding_document_path(document)
  end

  test "uploading without consent is rejected" do
    file = fixture_file_upload("sample_cv.pdf", "application/pdf")

    assert_no_difference -> { CandidateDocument.count } do
      post onboarding_cv_upload_path, params: { candidate_document: { file: file } }
    end
    assert_response :unprocessable_entity
  end

  test "the review form renders" do
    get edit_onboarding_profile_path
    assert_response :success
    assert_select "h1", /Review and complete your profile/
  end

  test "submitting an incomplete profile shows validation errors" do
    @user.create_candidate_profile! # exists from the upload step in the real flow

    patch onboarding_profile_path, params: { candidate_profile: { first_name: "Jan" }, consent: "1" }
    assert_response :unprocessable_entity
    assert_not @user.candidate_profile.reload.completed?
  end

  test "submitting a complete profile finishes onboarding and notifies the team" do
    params = {
      consent: "1",
      candidate_profile: {
        first_name: "Jan", last_name: "de Vries", email: "jan@example.nl",
        phone_number: "+31612345678", city: "Utrecht", job_function_id: @assistant.id,
        max_travel_time: 30, years_of_experience: 3, search_status: "active",
        available_from: Date.current.to_s, available_working_days: ["monday"],
        region_ids: [@region.id], employment_type_ids: [@employed.id],
        desired_gross_salary: 3000,
        candidate_languages_attributes: { "0" => { language_id: @language.id, level: "native" } }
      }
    }

    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      patch onboarding_profile_path, params: params
    end

    assert_redirected_to onboarding_done_path
    profile = @user.candidate_profile.reload
    assert profile.completed?
    assert_equal "Jan", profile.first_name
    assert_equal [@region], profile.regions.to_a
  end
end
