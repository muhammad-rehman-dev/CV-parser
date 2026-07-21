require "test_helper"

module Cv
  class ProfileMapperTest < ActiveSupport::TestCase
    setup do
      create_reference_data!
      @profile = create_candidate.create_candidate_profile!
    end

    test "maps simple fields, matches references and marks metadata" do
      result = ParsedResult.new(source: :llm, data: {
        first_name: "Jan", last_name: "de Vries", email: "jan@example.nl",
        phone_number: "+31612345678", city: "Utrecht", country: "Netherlands",
        job_function: "General dentist", years_of_experience: 8,
        languages: [{ name: "Dutch", level: "native" }],
        skills: ["Endodontics", "Underwater welding"],
        educations: [{ study: "Tandheelkunde", institution: "UvA", level: "Master", start_date: "2010-01-01", end_date: "2016-01-01" }],
        work_experiences: [{ job_title: "Dentist", company_name: "Clinic", current_job: true }]
      })

      ProfileMapper.new(@profile, result).call
      @profile.reload

      assert_equal "Jan", @profile.first_name
      assert_equal "Utrecht", @profile.city
      assert_equal @dentist, @profile.job_function
      assert_equal 8, @profile.years_of_experience

      assert_equal ["Dutch"], @profile.languages.map(&:name)
      assert_equal "native", @profile.candidate_languages.first.level

      # Known skill matched, unknown skill kept as a free-text suggestion.
      assert_includes @profile.skills.map(&:name), "Endodontics"
      suggestion = @profile.candidate_skills.detect(&:suggestion?)
      assert_equal "Underwater welding", suggestion.name
      assert suggestion.cv_suggested?

      assert_equal 1, @profile.educations.size
      assert_equal "Tandheelkunde", @profile.educations.first.study
      assert_equal 1, @profile.work_experiences.size
      assert @profile.work_experiences.first.current_job?

      # Metadata drives the review badges.
      assert @profile.extracted_from_cv?(:first_name)
      assert @profile.needs_review?(:job_function_id)
    end

    test "keeps a work experience when only the job title is present" do
      result = ParsedResult.new(source: :llm, data: {
        work_experiences: [
          { job_title: "Dental hygienist", company_name: nil, start_date: "2019-01-01" },
          { job_title: nil, company_name: nil }
        ]
      })

      ProfileMapper.new(@profile, result).call
      @profile.reload

      assert_equal 1, @profile.work_experiences.size
      assert_equal "Dental hygienist", @profile.work_experiences.first.job_title
      assert_nil @profile.work_experiences.first.company_name
    end

    test "does not invent data that is absent from the CV" do
      result = ParsedResult.new(source: :llm, data: {
        first_name: "Jan", email: nil, phone_number: nil, city: nil
      })

      ProfileMapper.new(@profile, result).call
      @profile.reload

      assert_equal "Jan", @profile.first_name
      assert_nil @profile.email
      assert_nil @profile.phone_number
      assert_nil @profile.city
      assert_not @profile.extracted_from_cv?(:city)
    end

    test "ignores malformed emails from the parser" do
      result = ParsedResult.new(source: :llm, data: { email: "not-an-email" })
      ProfileMapper.new(@profile, result).call
      assert_nil @profile.reload.email
    end

    test "does nothing when the result is not from a CV" do
      result = ParsedResult.new(source: :none)
      ProfileMapper.new(@profile, result).call
      assert_nil @profile.reload.first_name
    end
  end
end
