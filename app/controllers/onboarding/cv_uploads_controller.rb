module Onboarding
  # Step 1: upload a CV, store it privately and kick off background parsing.
  class CvUploadsController < BaseController
    include ConsentVerification

    def new
      @document = candidate_profile.candidate_documents.new
    end

    def create
      @document = candidate_profile.candidate_documents.new(document_params)
      @document.document_type = :cv

      unless consent_given?
        @document.errors.add(:base, "You must agree to the processing consent before uploading.")
        return render :new, status: :unprocessable_entity
      end

      @document.consent_accepted_at = Time.current

      if @document.save
        ParseCandidateCvJob.perform_later(@document.id)
        redirect_to status_onboarding_document_path(@document)
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def document_params
      params.require(:candidate_document).permit(:file)
    end
  end
end
