import { Controller } from "@hotwired/stimulus"

// Lives inside the color sample, which is an iframe on the Settings page.
// "Use this" hands the suggested color to the pickers outside it.
export default class extends Controller {
  use() {
    const { part, color } = this.element.dataset
    window.parent.postMessage({ themeSuggestion: { part, color } }, window.location.origin)
  }
}
