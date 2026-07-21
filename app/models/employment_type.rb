# A desired employment type; +category+ drives the compensation fields shown.
class EmploymentType < ApplicationRecord
  include ReferenceData

  CATEGORIES = %w[employed self_employed].freeze

  has_many :candidate_employment_types, dependent: :destroy
  has_many :candidate_profiles, through: :candidate_employment_types

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :category, inclusion: { in: CATEGORIES }

  def employed?
    category == "employed"
  end

  def self_employed?
    category == "self_employed"
  end
end
