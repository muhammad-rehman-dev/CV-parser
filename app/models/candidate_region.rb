class CandidateRegion < ApplicationRecord
  belongs_to :candidate_profile
  belongs_to :region

  validates :region_id, uniqueness: { scope: :candidate_profile_id }
end
