import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: { type: Number, default: 5000 } }

  connect() {
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, this.durationValue)
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.classList.add("opacity-0", "translate-x-full", "transition-all", "duration-300")
    setTimeout(() => this.element.remove(), 300)
  }
}
