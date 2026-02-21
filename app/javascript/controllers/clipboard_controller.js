import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]
  static values = { copiedText: { type: String, default: "Copied!" } }

  async copy() {
    const text = this.sourceTarget.value || this.sourceTarget.textContent
    try {
      await navigator.clipboard.writeText(text)
      const button = this.element.querySelector("button")
      if (button) {
        const original = button.textContent
        button.textContent = this.copiedTextValue
        setTimeout(() => { button.textContent = original }, 2000)
      }
    } catch {
      // Fallback for older browsers
      this.sourceTarget.select()
      document.execCommand("copy")
    }
  }
}
