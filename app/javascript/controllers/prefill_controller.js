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

    document.querySelector(params.scroll || "#get-options")?.scrollIntoView({ behavior: "smooth", block: "start" })
  }
}
