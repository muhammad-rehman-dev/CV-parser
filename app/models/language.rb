# A language a candidate can speak (multi-select, with an optional level).
class Language < ApplicationRecord
  include ReferenceData

  has_many :candidate_languages, dependent: :destroy
  has_many :candidate_profiles, through: :candidate_languages

  validates :name, presence: true, uniqueness: true
end
