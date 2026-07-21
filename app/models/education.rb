# A single education record. A candidate can have many.
class Education < ApplicationRecord
  LEVELS = {
    mbo: 0,
    hbo: 1,
    bachelor: 2,
    master: 3,
    doctor: 4,
    course: 5
  }.freeze

  belongs_to :candidate_profile

  enum :level, LEVELS

  validates :study, presence: true
  validate :end_after_start

  private

  def end_after_start
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "must be on or after the start date")
  end
end
