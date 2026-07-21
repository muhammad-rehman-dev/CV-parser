import { Controller } from "@hotwired/stimulus"

// Add/remove repeatable nested records (education, work experience).
export default class extends Controller {
  static targets = ["template", "list"]

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.listTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-nested-form-row]")
    const idField = row.querySelector("input[name*='[id]']")
    const destroyField = row.querySelector("input[name*='_destroy']")
    if (idField && destroyField) {
      destroyField.value = "1"
      row.classList.add("hidden")
    } else {
      row.remove()
    }
  }
}
