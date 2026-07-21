# A fixed platform job category (e.g. "General dentist") used for matching.
class JobFunction < ApplicationRecord
  include ReferenceData

  has_many :skills, dependent: :nullify
  has_many :candidate_profiles, dependent: :nullify

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
