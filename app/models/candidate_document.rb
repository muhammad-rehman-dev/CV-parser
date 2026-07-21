# A candidate's uploaded CV, stored privately via Active Storage and parsed in
# the background (see ParseCandidateCvJob).
class CandidateDocument < ApplicationRecord
  include ParsingStatus

  ACCEPTED_CONTENT_TYPES = {
    "application/pdf" => "pdf",
    "application/msword" => "doc",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => "docx"
  }.freeze

  belongs_to :candidate_profile

  has_one_attached :file

  enum :document_type, { cv: 0 }, default: :cv

  validates :file, presence: true
  validate :acceptable_file_type
  validate :acceptable_file_size

  before_validation :capture_file_metadata, on: :create

  scope :recent_first, -> { order(created_at: :desc) }

  def extension
    ACCEPTED_CONTENT_TYPES[content_type]
  end

  private

  def capture_file_metadata
    return unless file.attached?

    self.original_filename = file.filename.to_s
    self.content_type = file.content_type
    self.file_size = file.byte_size
  end

  def acceptable_file_type
    return unless file.attached?
    return if ACCEPTED_CONTENT_TYPES.key?(file.content_type)

    errors.add(:file, "must be a PDF, DOC or DOCX file")
  end

  def acceptable_file_size
    return unless file.attached?

    max = Setting.max_cv_file_size_bytes
    return if file.byte_size <= max

    errors.add(:file, "is too large (maximum is #{max / 1.megabyte} MB)")
  end
end
