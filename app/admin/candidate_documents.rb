ActiveAdmin.register CandidateDocument do
  menu false
  actions :index, :show

  member_action :download do
    document = CandidateDocument.find(params[:id])
    if document.file.attached?
      send_data document.file.download,
                filename: document.original_filename,
                type: document.content_type,
                disposition: "inline"
    else
      redirect_to admin_candidate_document_path(document), alert: "No file attached."
    end
  end
end
