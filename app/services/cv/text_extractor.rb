require "pdf-reader"
require "docx"

module Cv
  # Best-effort plain-text extraction from an uploaded CV (PDF/DOC/DOCX).
  # Returns "" rather than raising so the flow can fall back to manual entry.
  class TextExtractor
    def initialize(document)
      @document = document
    end

    def call
      return "" unless @document.file.attached?

      @document.file.blob.open do |file|
        case @document.content_type
        when "application/pdf"
          extract_pdf(file.path)
        when "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
          extract_docx(file.path)
        when "application/msword"
          extract_doc(file.path)
        else
          ""
        end
      end
    rescue StandardError => e
      Rails.logger.warn("[Cv::TextExtractor] extraction failed: #{e.class}: #{e.message}")
      ""
    end

    private

    def extract_pdf(path)
      reader = PDF::Reader.new(path)
      reader.pages.map(&:text).join("\n").strip
    end

    def extract_docx(path)
      doc = Docx::Document.open(path)
      doc.paragraphs.map(&:text).join("\n").strip
    end

    # No reliable pure-Ruby parser for legacy binary .doc; scrape printable runs.
    def extract_doc(path)
      binary = File.binread(path)
      binary.scan(/[[:print:]]{4,}/).join(" ").squeeze(" ").strip
    end
  end
end
