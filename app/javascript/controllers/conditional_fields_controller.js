import { Controller } from "@hotwired/stimulus"

// Shows/hides fields based on job function and employment type; server re-validates on save.
export default class extends Controller {
  static targets = [
    "jobFunction", "employmentType",
    "big", "revenue", "salary", "percentage",
    "skillGroup"
  ]

  connect() {
    this.refresh()
  }

  refresh() {
    const option = this.jobFunctionTarget.selectedOptions[0]
    const requiresBig = option ? option.dataset.requiresBig === "true" : false
    const revenueBased = option ? option.dataset.revenueBased === "true" : false
    const functionId = option ? option.value : ""

    const categories = this.employmentTypeTargets
      .filter((input) => input.checked)
      .map((input) => input.dataset.category)

    this.toggle(this.bigTargets, requiresBig)
    this.toggle(this.revenueTargets, revenueBased)
    this.toggle(this.salaryTargets, categories.includes("employed"))
    this.toggle(this.percentageTargets, categories.includes("self_employed"))

    this.skillGroupTargets.forEach((group) => {
      group.classList.toggle("hidden", group.dataset.jobFunctionId !== functionId)
    })
  }

  toggle(elements, visible) {
    elements.forEach((element) => element.classList.toggle("hidden", !visible))
  }
}
