# Parses an uploaded CV in the background and prefills the candidate profile.
# On any failure the document is marked failed so the candidate can continue manually.
class ParseCandidateCvJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    document = CandidateDocument.find_by(id: document_id)
    return if document.nil?

    document.start_processing!

    result = Cv::Parser.new(document).call
    Cv::ProfileMapper.new(document.candidate_profile, result).call

    document.mark_completed!
  rescue StandardError => e
    Rails.logger.error("[ParseCandidateCvJob] failed for document #{document_id}: #{e.class}: #{e.message}")
    document&.mark_failed!
  end
end
