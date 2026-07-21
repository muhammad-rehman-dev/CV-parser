# Admin-managed key/value config store; values are cast to +value_type+ on read.
class Setting < ApplicationRecord
  VALUE_TYPES = %w[string integer boolean].freeze

  DEFAULT_MAX_CV_FILE_SIZE_MB = 25

  validates :key, presence: true, uniqueness: true
  validates :value_type, inclusion: { in: VALUE_TYPES }

  def self.fetch(key, default = nil)
    setting = find_by(key: key.to_s)
    setting ? setting.typed_value : default
  end

  def self.max_cv_file_size_bytes
    fetch(:max_cv_file_size_mb, DEFAULT_MAX_CV_FILE_SIZE_MB).to_i.megabytes
  end

  def typed_value
    case value_type
    when "integer" then value.to_i
    when "boolean" then ActiveModel::Type::Boolean.new.cast(value)
    else value
    end
  end
end
