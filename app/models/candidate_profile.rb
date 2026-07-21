# The central onboarding profile aggregating all candidate data. Required
# validations only run in the :complete context (final save).
class CandidateProfile < ApplicationRecord
  include FieldMetadata

  TRANSPORT_TYPES = %w[bike scooter public_transport car].freeze
  WORKING_DAYS = %w[monday tuesday wednesday thursday friday saturday sunday].freeze

  belongs_to :user
  belongs_to :job_function, optional: true

  has_many :candidate_documents, dependent: :destroy
  has_many :educations, dependent: :destroy
  has_many :work_experiences, dependent: :destroy

  has_many :candidate_regions, dependent: :destroy
  has_many :regions, through: :candidate_regions

  has_many :candidate_employment_types, dependent: :destroy
  has_many :employment_types, through: :candidate_employment_types

  has_many :candidate_languages, dependent: :destroy
  has_many :languages, through: :candidate_languages

  has_many :candidate_skills, dependent: :destroy
  has_many :skills, through: :candidate_skills

  enum :search_status, { active: 0, passive: 1, inactive: 2 }, prefix: :search
  # Values already carry a "big_" prefix, giving helpers like #big_registered?.
  enum :big_registration_status,
       { big_registered: 0, big_in_progress: 1, big_under_supervision: 2, big_not_applicable: 3 }

  accepts_nested_attributes_for :educations, allow_destroy: true,
    reject_if: ->(attrs) { attrs.except("id", "_destroy").values.all?(&:blank?) }
  accepts_nested_attributes_for :work_experiences, allow_destroy: true,
    reject_if: ->(attrs) { attrs.except("id", "_destroy", "current_job").values.all?(&:blank?) }
  accepts_nested_attributes_for :candidate_languages, allow_destroy: true,
    reject_if: ->(attrs) { attrs["language_id"].blank? }

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :transport_types, subset: { in: TRANSPORT_TYPES }
  validates :available_working_days, subset: { in: WORKING_DAYS }

  # Full ruleset for a finished profile; only runs on the final "Save profile" step.
  with_options on: :complete do
    validates :first_name, :last_name, :email, :phone_number, :city, presence: true
    validates :job_function, presence: true
    validates :max_travel_time, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :years_of_experience, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :search_status, presence: true
    validates :available_from, presence: true

    validate :valid_phone_number
    validate :at_least_one_region
    validate :at_least_one_employment_type
    validate :at_least_one_language
    validate :at_least_one_working_day

    validates :desired_gross_salary, presence: true,
              numericality: { greater_than_or_equal_to: 0 }, if: :employed?
    validates :desired_percentage, presence: true,
              numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, if: :self_employed?
    validates :average_daily_revenue, presence: true,
              numericality: { greater_than_or_equal_to: 0 }, if: :revenue_based?
    validates :big_registration_status, presence: true, if: :requires_big?
    validates :big_number, presence: true, if: :big_registered?
  end

  def employed?
    employment_types.any?(&:employed?)
  end

  def self_employed?
    employment_types.any?(&:self_employed?)
  end

  def requires_big?
    job_function&.requires_big_registration?
  end

  def revenue_based?
    job_function&.revenue_based?
  end

  def full_name
    [first_name, last_name].compact_blank.join(" ")
  end

  def completed?
    completed_at.present?
  end

  def latest_cv
    candidate_documents.cv.recent_first.first
  end

  private

  def valid_phone_number
    return if phone_number.blank?
    return if Phonelib.valid?(phone_number)

    errors.add(:phone_number, "is not a valid phone number")
  end

  def at_least_one_region
    errors.add(:regions, "must include at least one preferred region") if regions.empty?
  end

  def at_least_one_employment_type
    errors.add(:employment_types, "must include at least one employment type") if employment_types.empty?
  end

  def at_least_one_language
    errors.add(:languages, "must include at least one language") if candidate_languages.reject(&:marked_for_destruction?).empty?
  end

  def at_least_one_working_day
    errors.add(:available_working_days, "must include at least one working day") if available_working_days.compact_blank.empty?
  end
end
