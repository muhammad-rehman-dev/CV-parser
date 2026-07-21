# Per-field provenance (jsonb) that drives the review badges on the profile form.
module FieldMetadata
  extend ActiveSupport::Concern

  def metadata_for(field)
    field_metadata[field.to_s] || {}
  end

  def extracted_from_cv?(field)
    metadata_for(field)["source"] == "cv"
  end

  def needs_review?(field)
    metadata_for(field)["needs_review"] == true
  end
end
