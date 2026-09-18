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
    target?.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  formShowsFrom(section, form) {
    if (!form) return true
    const offset = parseFloat(getComputedStyle(section).scrollMarginTop) || 0
    const formTop = form.getBoundingClientRect().top - section.getBoundingClientRect().top + offset
    return formTop + Math.min(form.offsetHeight, 200) <= window.innerHeight
  }
}
