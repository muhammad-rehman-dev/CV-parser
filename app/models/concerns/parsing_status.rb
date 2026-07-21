# Parsing status enum and state transitions for an uploaded document.
module ParsingStatus
  extend ActiveSupport::Concern

  included do
    enum :parsing_status, { pending: 0, processing: 1, completed: 2, failed: 3 }, default: :pending
  end

  def start_processing!
    update!(parsing_status: :processing)
  end

  def mark_completed!
    update!(parsing_status: :completed, parsed_at: Time.current)
  end

  def mark_failed!
    update!(parsing_status: :failed, parsed_at: Time.current)
  end

  def parsing_finished?
    completed? || failed?
  end
end
