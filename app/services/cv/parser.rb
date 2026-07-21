module Cv
  # Extracts text, then structured data via the LLM (falling back to the
  # heuristic extractor). Always returns a Cv::ParsedResult; never raises.
  class Parser
    def initialize(document)
      @document = document
    end

    def call
      text = TextExtractor.new(@document).call
      return ParsedResult.new(source: :none) if text.blank?

      if LlmExtractor.configured?
        parse_with_llm(text)
      else
        Rails.logger.info("[Cv::Parser] no LLM key configured, using heuristic extractor")
        heuristic(text)
      end
    end

    private

    def parse_with_llm(text)
      data = LlmExtractor.new(text).call
      ParsedResult.new(data: data, source: :llm)
    rescue LlmExtractor::ExtractionError => e
      Rails.logger.warn("[Cv::Parser] LLM extraction failed, using heuristic: #{e.message}")
      heuristic(text)
    end

    def heuristic(text)
      data = HeuristicExtractor.new(text).call
      ParsedResult.new(data: data, source: :heuristic)
    end
  end
end
