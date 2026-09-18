import { Controller } from "@hotwired/stimulus"

// Closes a <details> menu on a click outside it or on Escape, like a menu should.
export default class extends Controller {
  closeOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  close() {
    this.element.open = false
  }
}
