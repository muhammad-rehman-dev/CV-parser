import { Controller } from "@hotwired/stimulus"

// Drag-and-drop CV upload; the hidden file input stays the source of truth.
export default class extends Controller {
  static targets = ["input", "dropzone", "filename"]

  dragover(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("border-teal-500", "bg-teal-50")
  }

  dragleave(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-teal-500", "bg-teal-50")
  }

  drop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-teal-500", "bg-teal-50")
    if (event.dataTransfer.files.length > 0) {
      this.inputTarget.files = event.dataTransfer.files
      this.selected()
    }
  }

  selected() {
    const file = this.inputTarget.files[0]
    this.filenameTarget.textContent = file ? file.name : ""
  }
}
