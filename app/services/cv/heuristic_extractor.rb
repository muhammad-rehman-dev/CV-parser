module Cv
  # Pure-Ruby fallback extractor used when no LLM is configured or the LLM fails.
  # Only reports values that literally appear in the text; never guesses.
  class HeuristicExtractor
    EMAIL_REGEXP = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i
    # [:blank:] (not \s) so numbers don't run into the next line.
    PHONE_CANDIDATE_REGEXP = /\+?\d[\d[:blank:]().\-]{6,}\d/
    YEARS_REGEXP = /(\d{1,2})\s*(?:\+)?\s*(?:years?|jaar|jr)\b/i

    def initialize(text)
      @text = text.to_s
    end

    def call
      return {} if @text.blank?

      {
        email: extract_email,
        phone_number: extract_phone,
        years_of_experience: extract_years,
        job_function: match_job_function,
        languages: match_languages,
        skills: match_skills
      }.compact
    end

    private

    def extract_email
      @text[EMAIL_REGEXP]
    end

    def extract_phone
      @text.scan(PHONE_CANDIDATE_REGEXP).map(&:strip).find { |candidate| Phonelib.valid?(candidate) }
    end

    def extract_years
      match = @text.match(YEARS_REGEXP)
      match && match[1].to_i
    end

    def match_job_function
      JobFunction.active.ordered.detect { |fn| mentions?(fn.name) }&.name
    end

    def match_languages
      Language.active.ordered.select { |lang| mentions?(lang.name) }
              .map { |lang| { name: lang.name, level: nil } }
    end

    def match_skills
      Skill.active.distinct.pluck(:name).uniq.select { |name| mentions?(name) }
    end

    def mentions?(term)
      return false if term.blank?

      @text.match?(/\b#{Regexp.escape(term)}\b/i)
    end
  end
end
