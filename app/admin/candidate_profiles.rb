ActiveAdmin.register CandidateProfile do
  menu priority: 2, label: "Candidates"
  actions :index, :show

  filter :first_name
  filter :last_name
  filter :email
  filter :city
  filter :job_function
  filter :completed_at

  index do
    selectable_column
    id_column
    column :full_name
    column :email
    column :city
    column :job_function
    column("Completed") { |p| p.completed? ? status_tag("yes", class: "ok") : status_tag("no") }
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :full_name
      row :email
      row :phone_number
      row :city
      row :country
      row :job_function
      row :search_status
      row("Preferred regions") { |p| p.regions.map(&:name).join(", ") }
      row :max_travel_time
      row("Transport") { |p| p.transport_types.map(&:humanize).join(", ") }
      row("Employment types") { |p| p.employment_types.map(&:name).join(", ") }
      row :desired_gross_salary
      row :desired_percentage
      row :average_daily_revenue
      row :big_registration_status
      row :big_number
      row :years_of_experience
      row("Available working days") { |p| p.available_working_days.map(&:humanize).join(", ") }
      row :available_from
      row :notice_period
      row :professional_summary
      row :motivation
      row :internal_notes
      row :completed_at
    end

    panel "Languages" do
      table_for candidate_profile.candidate_languages do
        column("Language") { |cl| cl.language&.name }
        column :level
      end
    end

    panel "Skills" do
      table_for candidate_profile.candidate_skills do
        column("Skill") { |cs| cs.display_name }
        column("Source") { |cs| cs.source.humanize }
      end
    end

    panel "Education" do
      table_for candidate_profile.educations do
        column :study
        column :institution
        column :level
        column :start_date
        column :end_date
      end
    end

    panel "Work experience" do
      table_for candidate_profile.work_experiences do
        column :job_title
        column :company_name
        column :start_date
        column :end_date
        column :current_job
      end
    end

    panel "Documents" do
      table_for candidate_profile.candidate_documents.recent_first do
        column(:original_filename)
        column(:parsing_status) { |d| d.parsing_status }
        column(:uploaded) { |d| d.created_at }
        column("") do |d|
          link_to("Download", download_admin_candidate_document_path(d)) if d.file.attached?
        end
      end
    end
  end
end
