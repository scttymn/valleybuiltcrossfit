import { Controller } from "@hotwired/stimulus"

// Desktop: cards act like tabs, one program's details always showing.
// Tablet/phone: cards act like an accordion; tapping the open one closes it.
// Which mode applies is decided by the CSS (the +/− toggle is only shown in
// accordion mode), so the breakpoint lives in one place.

export default class extends Controller {
  static targets = ["card", "panel"]

  // Desktop keeps the first program open; in accordion mode everything starts closed.
  connect() {
    if (this.hasCardTarget && this.accordion(this.cardTargets[0])) this.show(-1)
    this.element.dataset.ready = ""
  }

  toggle(event) {
    const card = event.currentTarget
    const index = this.cardTargets.indexOf(card)
    const alreadyOpen = card.getAttribute("aria-expanded") === "true"

    if (alreadyOpen) {
      if (this.accordion(card)) this.show(-1)
      return
    }

    this.show(index)
    if (this.accordion(card)) this.bringIntoView(card)
  }

  accordion(card) {
    return getComputedStyle(card.querySelector(".program-card__toggle")).display !== "none"
  }

  show(index) {
    this.cardTargets.forEach((card, i) => card.setAttribute("aria-expanded", String(i === index)))
    this.panelTargets.forEach((panel, i) => (panel.hidden = i !== index))
  }

  // Closing a program above can shift the tapped card off screen.
  bringIntoView(card) {
    requestAnimationFrame(() => {
      if (card.getBoundingClientRect().top < 80) card.scrollIntoView({ behavior: "smooth", block: "start" })
    })
  }
}
