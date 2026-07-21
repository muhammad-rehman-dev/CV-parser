# Join between a candidate and a language, carrying the proficiency level.
class CandidateLanguage < ApplicationRecord
  belongs_to :candidate_profile
  belongs_to :language

  validates :language_id, uniqueness: { scope: :candidate_profile_id }

  delegate :name, to: :language, prefix: false, allow_nil: true
end
