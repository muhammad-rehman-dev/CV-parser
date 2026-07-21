class CandidateEmploymentType < ApplicationRecord
  belongs_to :candidate_profile
  belongs_to :employment_type

  validates :employment_type_id, uniqueness: { scope: :candidate_profile_id }
end
