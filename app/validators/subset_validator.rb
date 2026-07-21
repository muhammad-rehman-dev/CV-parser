# Validates that every element of an array attribute is included in a given set.
#
#   validates :transport_types, subset: { in: %w[bike car] }
class SubsetValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    allowed = Array(options.fetch(:in))
    invalid = Array(value).compact_blank - allowed
    return if invalid.empty?

    record.errors.add(attribute, options[:message] || "contains invalid values: #{invalid.join(', ')}")
  end
end
