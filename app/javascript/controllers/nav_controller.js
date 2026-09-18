import { Controller } from "@hotwired/stimulus"

// Mobile menu toggle.
export default class extends Controller {
  static targets = ["menu", "toggle"]

  toggle() {
    this.setOpen(this.menuTarget.hidden)
  }

  close() {
    this.setOpen(false)
  }

  setOpen(open) {
    this.menuTarget.hidden = !open
    this.toggleTarget.setAttribute("aria-expanded", String(open))
  }
}
