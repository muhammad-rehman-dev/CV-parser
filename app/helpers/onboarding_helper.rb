module OnboardingHelper
  # Status label next to a field: "Please check" / "Extracted from CV" / "Missing".
  def review_badge(profile, field, required: false, blank: nil)
    if profile.needs_review?(field)
      badge_tag("Please check", "bg-amber-100 text-amber-800")
    elsif profile.extracted_from_cv?(field)
      badge_tag("Extracted from CV", "bg-teal-100 text-teal-800")
    elsif required && (blank.nil? ? profile.public_send(field).blank? : blank)
      badge_tag("Missing", "bg-red-100 text-red-700")
    end
  end

  def badge_tag(text, classes)
    content_tag(:span, text, class: "ml-2 inline-block rounded-full px-2 py-0.5 text-xs font-medium #{classes}")
  end

  def onboarding_input_classes
    "mt-1 block w-full rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-teal-500 focus:ring-teal-500"
  end

  # Red asterisk marking fields required on final save.
  def required_marker
    content_tag(:abbr, "*",
      title: "Required",
      class: "ml-0.5 font-semibold text-red-500 no-underline",
      "aria-label": "required")
  end
end
