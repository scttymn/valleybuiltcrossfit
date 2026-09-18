import { Controller } from "@hotwired/stimulus"

// Buttons like "Book an intro" or "Ask about personal training" are plain
// anchors to the options form (#get-options); this ticks the matching options
// as they go. The browser does the jump, so it works on every device, and after
// the mobile menu has closed. The links opt out of Turbo, which would swap in a
// cached copy of the page and undo the ticks.
export default class extends Controller {
  apply({ params }) {
    const fields = { interest: params.interest, starting_from: params.startingFrom, who: params.who }

    for (const [field, value] of Object.entries(fields)) {
      if (!value) continue

      const input = this.element.querySelector(`input[name="lead[${field}]"][value="${CSS.escape(value)}"]`)
      if (input) {
        input.checked = true
        input.dispatchEvent(new Event("change", { bubbles: true }))
      }
    }
  }
}
