module Cv
  # Value object returned by Cv::Parser: extracted +data+ plus its +source+.
  class ParsedResult
    attr_reader :data, :source

    def initialize(data: {}, source: :none)
      @data = (data || {}).deep_symbolize_keys
      @source = source
    end

    def any?
      data.values.any?(&:present?)
    end

    def from_cv?
      source != :none
    end
  end
end
