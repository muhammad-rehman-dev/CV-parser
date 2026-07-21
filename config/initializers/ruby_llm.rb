# Configures ruby_llm for Cv::LlmExtractor. Provider via CV_LLM_PROVIDER; with no
# API key, Cv::Parser falls back to the local heuristic extractor.
RubyLLM.configure do |config|
  # Use the association-based Rails API (silences the legacy warning).
  config.use_new_acts_as = true

  config.gemini_api_key = ENV["GEMINI_API_KEY"].presence
  config.openai_api_key = ENV["OPENAI_API_KEY"].presence

  # Groq exposes an OpenAI-compatible endpoint; use it when only a Groq key is set.
  if ENV["GROQ_API_KEY"].present? && ENV["OPENAI_API_KEY"].blank?
    config.openai_api_key = ENV["GROQ_API_KEY"]
    config.openai_api_base = "https://api.groq.com/openai/v1"
  end

  # Single fast timeout; Cv::LlmExtractor handles retries and model fallback.
  config.request_timeout = 45
  config.max_retries = 1
end
