import { Controller } from "@hotwired/stimulus"

// Buttons like "Book an intro" or "Ask about personal training" jump to the
// options form and pre-select the matching chips.
export default class extends Controller {
  apply(event) {
    // Scroll ourselves: following the link would be a Turbo visit, and the
    // cached page it swaps in would undo everything we're about to set.
    event.preventDefault()

    const { params } = event
    const fields = { interest: params.interest, starting_from: params.startingFrom, who: params.who }

    for (const [field, value] of Object.entries(fields)) {
      if (!value) continue

      const input = this.element.querySelector(`input[name="lead[${field}]"][value="${CSS.escape(value)}"]`)
      if (input) {
        input.checked = true
        input.dispatchEvent(new Event("change", { bubbles: true }))
      }
    }

    // Wait a frame: the mobile menu closes on the same tap, and measuring
    // before it's gone overshoots by the menu's height.
    requestAnimationFrame(() => this.scrollTo(params.scroll))
  }

  // The form, or the section a link names (Membership) when the form still
  // shows from there. On a phone the form sits below the section's list, so
  // it's the form itself.
  scrollTo(selector) {
    const form = document.querySelector("#get-options")
    const section = selector && document.querySelector(selector)
    const target = section && this.formShowsFrom(section, form) ? section : form
    if (!target) return
    target.scrollIntoView({ behavior: "smooth", block: "start" })
    this.settleOn(target)
    // Someone who starts scrolling themselves isn't pulled back afterward.
    const stop = () => clearInterval(this.settling)
    for (const type of [ "touchstart", "wheel", "keydown" ]) addEventListener(type, stop, { once: true, passive: true })
  }

  // A smooth scroll heads for where the target was when it started. If the
  // page shifts on the way (a photo loading above it; Safari keeps no scroll
  // anchor), it stops short. Once the page stops moving, finish the trip.
  settleOn(target, corrections = 2) {
    clearInterval(this.settling)
    let last = null
    this.settling = setInterval(() => {
      if (window.scrollY !== last) { last = window.scrollY; return }
      clearInterval(this.settling)
      const margin = parseFloat(getComputedStyle(target).scrollMarginTop) || 0
      const off = target.getBoundingClientRect().top - margin
      const atBottom = window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2
      if (Math.abs(off) > 4 && !atBottom && corrections > 0) {
        target.scrollIntoView({ behavior: "smooth", block: "start" })
        this.settleOn(target, corrections - 1)
      }
    }, 150)
  }

  disconnect() {
    clearInterval(this.settling)
  }

  formShowsFrom(section, form) {
    if (!form) return true
    const offset = parseFloat(getComputedStyle(section).scrollMarginTop) || 0
    const formTop = form.getBoundingClientRect().top - section.getBoundingClientRect().top + offset
    return formTop + Math.min(form.offsetHeight, 200) <= window.innerHeight
  }
}
