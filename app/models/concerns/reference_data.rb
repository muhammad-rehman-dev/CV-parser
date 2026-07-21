# Shared scopes and label for admin-managed lookup models.
module ReferenceData
  extend ActiveSupport::Concern

  included do
    scope :active,  -> { where(active: true) }
    scope :ordered, -> { order(:position, :name) }
  end

  def to_s
    name
  end
end
