module Onboarding
  # CV processing/polling screen and private downloads, scoped to the candidate.
  class DocumentsController < BaseController
    before_action :set_document

    def status
      respond_to do |format|
        format.html
        format.json do
          render json: {
            status: @document.parsing_status,
            finished: @document.parsing_finished?,
            redirect_url: edit_onboarding_profile_path
          }
        end
      end
    end

    def show
      return head :not_found unless @document.file.attached?

      send_data @document.file.download,
                filename: @document.original_filename,
                type: @document.content_type,
                disposition: "inline"
    end

    private

    def set_document
      @document = candidate_profile.candidate_documents.find(params[:id])
    end
  end
end
