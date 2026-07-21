# A single work experience record; a candidate can have many.
class WorkExperience < ApplicationRecord
  belongs_to :candidate_profile

  # Require at least one of title/employer so partial CV-extracted roles survive.
  validates :job_title, presence: true, unless: -> { company_name.present? }
  validates :company_name, presence: true, unless: -> { job_title.present? }
  validate :end_after_start

  before_validation :clear_end_date_when_current

  private

  def clear_end_date_when_current
    self.end_date = nil if current_job?
  end

  def end_after_start
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "must be on or after the start date")
  end
end
