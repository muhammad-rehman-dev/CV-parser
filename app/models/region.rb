# A preferred working region a candidate can select (multi-select).
class Region < ApplicationRecord
  include ReferenceData

  has_many :candidate_regions, dependent: :destroy
  has_many :candidate_profiles, through: :candidate_regions

  validates :name, presence: true, uniqueness: true
end
