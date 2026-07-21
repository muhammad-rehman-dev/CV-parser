import { Controller } from "@hotwired/stimulus"

// Polls the parsing status endpoint and drives the animated progress bar,
// jumping to 100% once the server confirms parsing has finished.
export default class extends Controller {
  static values = { url: String, finished: Boolean, redirect: String }
  static targets = ["bar", "percent", "message", "step", "stepIcon"]

  messages = [
    "Reading your CV…",
    "Extracting your details…",
    "Matching skills and experience…",
    "Almost there…"
  ]

  connect() {
    if (this.finishedValue) return

    this.progress = 5
    this.startedAt = Date.now()
    this.animate()
    this.rotateMessages()
    this.timer = setInterval(() => this.check(), 2000)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
    if (this.animation) clearInterval(this.animation)
    if (this.messageTimer) clearInterval(this.messageTimer)
  }

  animate() {
    // Ease toward a 90% ceiling until the server confirms completion.
    this.animation = setInterval(() => {
      const ceiling = 90
      if (this.progress < ceiling) {
        this.progress += Math.max(0.4, (ceiling - this.progress) * 0.04)
        this.render()
      }
    }, 300)
  }

  rotateMessages() {
    let index = 0
    this.messageTimer = setInterval(() => {
      index = Math.min(index + 1, this.messages.length - 1)
      if (this.hasMessageTarget) this.messageTarget.textContent = this.messages[index]
    }, 3500)
  }

  render() {
    const value = Math.round(this.progress)
    if (this.hasBarTarget) this.barTarget.style.width = `${value}%`
    if (this.hasPercentTarget) this.percentTarget.textContent = `${value}%`

    this.stepTargets.forEach((step) => {
      const threshold = Number(step.dataset.threshold || 0)
      const icon = step.querySelector("[data-cv-status-target='stepIcon']")
      if (value >= threshold) {
        if (icon) {
          icon.textContent = "✓"
          icon.classList.remove("text-slate-300")
          icon.classList.add("text-teal-600")
        }
      }
    })
  }

  async check() {
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) return
      const data = await response.json()

      if (data.status === "failed") {
        window.location.reload()
        return
      }

      if (data.finished) {
        this.complete(data.redirect_url)
      }
    } catch (_error) {
    }
  }

  complete(redirectUrl) {
    if (this.timer) clearInterval(this.timer)
    if (this.animation) clearInterval(this.animation)
    if (this.messageTimer) clearInterval(this.messageTimer)

    this.progress = 100
    this.render()
    if (this.hasMessageTarget) this.messageTarget.textContent = "Done! Taking you to your profile…"

    setTimeout(() => {
      window.location = redirectUrl || this.redirectValue
    }, 600)
  }
}
