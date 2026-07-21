# Join between a candidate and a skill. A nil +skill+ with a +name+ is a
# free-text CV suggestion kept for recruiter review.
class CandidateSkill < ApplicationRecord
  belongs_to :candidate_profile
  belongs_to :skill, optional: true

  enum :source, { manual: 0, cv_matched: 1, cv_suggested: 2 }, default: :manual

  validates :name, presence: true, unless: :skill
  validate :skill_or_name_present

  def suggestion?
    skill_id.nil? && name.present?
  end

  def display_name
    skill&.name || name
  end

  private

  def skill_or_name_present
    return if skill.present? || name.present?

    errors.add(:base, "must reference a skill or provide a name")
  end
end
