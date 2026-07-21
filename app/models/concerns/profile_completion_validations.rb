# Validations that only run on final onboarding submission (the :complete context).
module ProfileCompletionValidations
  extend ActiveSupport::Concern

  included do
    validates :first_name, :last_name, :email, :phone_number, :city,
              presence: true, on: :complete
    validates :job_function, presence: true, on: :complete
    validates :max_travel_time, presence: true,
              numericality: { greater_than_or_equal_to: 0 }, on: :complete
    validates :years_of_experience, presence: true,
              numericality: { greater_than_or_equal_to: 0 }, on: :complete
    validates :search_status, presence: true, on: :complete
    validates :available_from, presence: true, on: :complete

    validate :valid_phone_number, on: :complete
    validate :at_least_one_region, on: :complete
    validate :at_least_one_employment_type, on: :complete
    validate :at_least_one_language, on: :complete
    validate :at_least_one_working_day, on: :complete

    validates :desired_gross_salary, presence: true,
              numericality: { greater_than_or_equal_to: 0 },
              if: :employed?, on: :complete
    validates :desired_percentage, presence: true,
              numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
              if: :self_employed?, on: :complete
    validates :average_daily_revenue, presence: true,
              numericality: { greater_than_or_equal_to: 0 },
              if: :revenue_based?, on: :complete
    validates :big_registration_status, presence: true, if: :requires_big?, on: :complete
    validates :big_number, presence: true, if: :big_registered?, on: :complete
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
