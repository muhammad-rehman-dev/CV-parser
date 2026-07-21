module Cv
  # Extracts structured candidate data from CV text via ruby_llm. Provider is set
  # with CV_LLM_PROVIDER; without an API key Cv::Parser uses the heuristic fallback.
  class LlmExtractor
    class ExtractionError < StandardError; end

    PROVIDERS = {
      "gemini" => {
        provider: :gemini, env: "GEMINI_API_KEY", default_model: "gemini-flash-latest",
        # lite is tried when the primary reports "high demand".
        fallback_models: ["gemini-flash-latest", "gemini-flash-lite-latest"]
      },
      "groq"   => { provider: :openai, env: "GROQ_API_KEY",   default_model: "llama-3.3-70b-versatile" },
      "openai" => { provider: :openai, env: "OPENAI_API_KEY", default_model: "gpt-4o-mini" }
    }.freeze

    MAX_ROUNDS = 2

    SYSTEM_PROMPT = <<~PROMPT.freeze
      You extract structured data from candidate CVs for a dental recruitment
      platform. The CV may be in Dutch or English.

      Return ONLY a single JSON object, no prose, no markdown fences.

      Rules:
      - Never invent information. If a value is not clearly present in the CV,
        use null (or an empty array). Do not guess emails, phone numbers or dates.
      - Dates must be formatted as "YYYY-MM-DD"; if only a year/month is known use
        "YYYY-01-01" / "YYYY-MM-01". Use null when unknown.
      - "job_function" should be your best single guess of the dental role, using
        wording from the CV (e.g. "General dentist", "Dental hygienist").
      - "languages" is a list of { "name": string, "level": string|null }.
      - "skills" is a list of short skill names as strings.
      - "big_status" is one of "registered", "in_progress", "under_supervision",
        "not_applicable" or null.

      JSON shape:
      {
        "first_name": string|null,
        "last_name": string|null,
        "email": string|null,
        "phone_number": string|null,
        "city": string|null,
        "country": string|null,
        "languages": [{ "name": string, "level": string|null }],
        "skills": [string],
        "job_function": string|null,
        "years_of_experience": number|null,
        "big_number": string|null,
        "big_status": string|null,
        "professional_summary": string|null,
        "educations": [{
          "institution": string|null,
          "study": string|null,
          "city_and_country": string|null,
          "level": string|null,
          "start_date": string|null,
          "end_date": string|null
        }],
        "work_experiences": [{
          "job_title": string|null,
          "company_name": string|null,
          "responsibilities": string|null,
          "start_date": string|null,
          "end_date": string|null,
          "current_job": boolean
        }]
      }
    PROMPT

    def initialize(text)
      @text = text.to_s
    end

    def self.configured?
      config = PROVIDERS[provider_key]
      config.present? && ENV[config[:env]].present?
    end

    def self.provider_key
      ENV.fetch("CV_LLM_PROVIDER", "gemini").to_s.downcase
    end

    def call
      raise ExtractionError, "no LLM provider configured" unless self.class.configured?
      return {} if @text.blank?

      last_error = nil

      MAX_ROUNDS.times do |round|
        models.each do |model_name|
          return extract_with(model_name)
        rescue RubyLLM::Error, ExtractionError => e
          last_error = e
          Rails.logger.warn("[Cv::LlmExtractor] #{model_name} failed (round #{round + 1}): #{e.class}: #{e.message.to_s.lines.first&.strip}")
        end
        sleep(1.5 * (round + 1)) unless round == MAX_ROUNDS - 1
      end

      raise ExtractionError, "all model attempts failed: #{last_error&.class}: #{last_error&.message}"
    end

    private

    def config
      @config ||= PROVIDERS.fetch(self.class.provider_key)
    end

    def models
      configured = ENV["CV_LLM_MODEL"].presence
      list = [configured] + Array(config[:fallback_models])
      list << config[:default_model]
      list.compact.uniq
    end

    def extract_with(model_name)
      response = chat(model_name).with_instructions(SYSTEM_PROMPT).ask(user_prompt)
      parse_json(response.content)
    end

    def chat(model_name)
      chat = RubyLLM.chat(model: model_name, provider: config[:provider], assume_model_exists: true)
      chat = chat.with_temperature(0) if chat.respond_to?(:with_temperature)
      chat
    end

    def user_prompt
      "Extract the candidate data from the following CV text:\n\n#{@text}"
    end

    def parse_json(content)
      raw = content.is_a?(String) ? content : content.to_json
      json = raw[/\{.*\}/m]
      raise ExtractionError, "no JSON object in response" if json.blank?

      JSON.parse(json)
    rescue JSON::ParserError => e
      raise ExtractionError, "invalid JSON: #{e.message}"
    end
  end
end
