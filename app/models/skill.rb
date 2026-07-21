# A platform skill, optionally grouped under a job function.
class Skill < ApplicationRecord
  include ReferenceData

  belongs_to :job_function, optional: true

  has_many :candidate_skills, dependent: :destroy
  has_many :candidate_profiles, through: :candidate_skills

  validates :name, presence: true

  scope :for_function, ->(job_function) { where(job_function_id: job_function) }
end
