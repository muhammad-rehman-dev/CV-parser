require "test_helper"

module Cv
  class HeuristicExtractorTest < ActiveSupport::TestCase
    setup { create_reference_data! }

    test "extracts email, phone, years, and matches reference data" do
      text = <<~CV
        Jan de Vries - General dentist
        Email: jan.devries@example.nl
        Tel: +31 6 12345678
        8 years of experience.
        Languages: Dutch, English
        Skills: Endodontics, cooking
      CV

      result = HeuristicExtractor.new(text).call

      assert_equal "jan.devries@example.nl", result[:email]
      assert_equal "+31 6 12345678", result[:phone_number]
      assert_equal 8, result[:years_of_experience]
      assert_equal "General dentist", result[:job_function]
      assert_includes result[:languages], { name: "Dutch", level: nil }
      assert_includes result[:skills], "Endodontics"
      # Does not invent skills that are not in the platform list.
      assert_not_includes result[:skills], "cooking"
    end

    test "returns empty hash for blank text" do
      assert_equal({}, HeuristicExtractor.new("").call)
    end

    test "does not report an invalid phone number" do
      result = HeuristicExtractor.new("call me at 123").call
      assert_nil result[:phone_number]
    end
  end
end
