import { Controller } from "@hotwired/stimulus"

// "Just a question" hides the two qualifying questions — they only apply to
// someone thinking about joining.
export default class extends Controller {
  static targets = ["qualifying", "notes"]
  static values = { question: { type: String, default: "Just a question" } }

  connect() {
    this.refresh()
  }

  selectFirstInEachGroup() {
    for (const group of [ "starting_from", "who" ]) {
      const options = this.qualifyingTarget.querySelectorAll(`input[name="lead[${group}]"]`)
      if (options.length && ![ ...options ].some((option) => option.checked)) options[0].checked = true
    }
  }

  refresh() {
    const asking = this.element.querySelector('input[name="lead[interest]"]:checked')?.value === this.questionValue

    this.qualifyingTarget.hidden = asking
    this.qualifyingTarget.querySelectorAll("input").forEach((input) => {
      input.disabled = asking
      if (asking) input.checked = false
    })

    // Showing them: start each group on its first option rather than blank.
    if (!asking) this.selectFirstInEachGroup()

    if (this.hasNotesTarget) {
      this.notesTarget.placeholder = asking ? "What would you like to ask?" : "Anything we should know? (optional)"
      this.notesTarget.required = asking
    }
  }
}
