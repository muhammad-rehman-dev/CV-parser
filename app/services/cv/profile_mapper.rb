module Cv
  # Maps a Cv::ParsedResult onto a CandidateProfile: assigns fields, matches
  # reference records, builds nested records, and records review metadata. Only
  # writes values that are present, so missing data is never invented.
  class ProfileMapper
    # Inferred fields the candidate is asked to double check.
    UNCERTAIN_FIELDS = %w[job_function_id big_registration_status years_of_experience professional_summary].freeze

    EDUCATION_LEVELS = {
      "mbo" => :mbo, "hbo" => :hbo, "bachelor" => :bachelor,
      "master" => :master, "doctor" => :doctor, "phd" => :doctor, "course" => :course
    }.freeze

    BIG_STATUSES = {
      "registered" => :big_registered, "in_progress" => :big_in_progress,
      "under_supervision" => :big_under_supervision, "not_applicable" => :big_not_applicable
    }.freeze

    def initialize(profile, result)
      @profile = profile
      @result = result
      @data = result.data
      @metadata = {}
    end

    def call
      return @profile unless @result.from_cv?

      assign_personal_fields
      assign_job_function
      assign_experience_and_big
      assign_summary
      assign_languages
      assign_skills
      assign_educations
      assign_work_experiences

      @profile.field_metadata = @profile.field_metadata.merge(@metadata)
      @profile.save!
      @profile
    end

    private

    def assign_personal_fields
      set(:first_name, @data[:first_name])
      set(:last_name, @data[:last_name])
      set(:email, @data[:email]) if valid_email?(@data[:email])
      set(:phone_number, @data[:phone_number])
      set(:city, @data[:city])
      set(:country, @data[:country])
    end

    def assign_job_function
      name = @data[:job_function]
      return if name.blank?

      job_function = find_job_function(name)
      return if job_function.nil?

      @profile.job_function = job_function
      mark(:job_function_id)
    end

    def assign_experience_and_big
      years = @data[:years_of_experience]
      if years.present? && years.to_s.match?(/\A\d+\z/)
        set(:years_of_experience, years.to_i)
      end

      set(:big_number, @data[:big_number])

      status = BIG_STATUSES[@data[:big_status].to_s.downcase]
      if status
        @profile.big_registration_status = status
        mark(:big_registration_status)
      end
    end

    def assign_summary
      set(:professional_summary, @data[:professional_summary])
    end

    def assign_languages
      Array(@data[:languages]).each do |entry|
        entry = entry.symbolize_keys
        language = Language.active.find_by("LOWER(name) = ?", entry[:name].to_s.downcase.strip)
        next if language.nil?
        next if @profile.candidate_languages.any? { |cl| cl.language_id == language.id }

        @profile.candidate_languages.build(language: language, level: entry[:level].presence)
      end
    end

    def assign_skills
      Array(@data[:skills]).map { |s| s.to_s.strip }.reject(&:blank?).uniq.each do |name|
        skill = Skill.active.find_by("LOWER(name) = ?", name.downcase)
        if skill
          next if @profile.candidate_skills.any? { |cs| cs.skill_id == skill.id }

          @profile.candidate_skills.build(skill: skill, source: :cv_matched)
        else
          next if @profile.candidate_skills.any? { |cs| cs.skill_id.nil? && cs.name&.casecmp?(name) }

          @profile.candidate_skills.build(name: name, source: :cv_suggested)
        end
      end
    end

    def assign_educations
      Array(@data[:educations]).each do |entry|
        entry = entry.symbolize_keys
        next if entry[:study].blank?

        @profile.educations.build(
          institution: entry[:institution].presence,
          study: entry[:study],
          city_and_country: entry[:city_and_country].presence,
          level: EDUCATION_LEVELS[entry[:level].to_s.downcase],
          start_date: parse_date(entry[:start_date]),
          end_date: parse_date(entry[:end_date])
        )
      end
    end

    def assign_work_experiences
      Array(@data[:work_experiences]).each do |entry|
        entry = entry.symbolize_keys
        # Keep the role if it has a title or an employer; skip only empty entries.
        next if entry[:job_title].blank? && entry[:company_name].blank?

        @profile.work_experiences.build(
          job_title: entry[:job_title],
          company_name: entry[:company_name],
          responsibilities: entry[:responsibilities].presence,
          start_date: parse_date(entry[:start_date]),
          end_date: parse_date(entry[:end_date]),
          current_job: ActiveModel::Type::Boolean.new.cast(entry[:current_job]) || false
        )
      end
    end

    def set(field, value)
      return if value.blank?

      @profile.public_send("#{field}=", value)
      mark(field)
    end

    def mark(field)
      @metadata[field.to_s] = { "source" => "cv", "needs_review" => UNCERTAIN_FIELDS.include?(field.to_s) }
    end

    def find_job_function(name)
      normalized = name.to_s.downcase.strip
      JobFunction.active.find_by("LOWER(name) = ?", normalized) ||
        JobFunction.active.ordered.detect { |fn| normalized.include?(fn.name.downcase) || fn.name.downcase.include?(normalized) }
    end

    def valid_email?(value)
      value.present? && value.match?(URI::MailTo::EMAIL_REGEXP)
    end

    def parse_date(value)
      return nil if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
