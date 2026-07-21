class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :candidate_profile, dependent: :destroy

  # Returns the profile, creating an empty one on first access.
  def candidate_profile!
    candidate_profile || create_candidate_profile
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id email created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[candidate_profile]
  end
end
