import { Controller } from "@hotwired/stimulus"

// Marks a photo that failed to load, so it shows the missing-photo stripes
// rather than the browser's broken-image icon.
export default class extends Controller {
  connect() {
    this.image = this.element.querySelector("img")
    if (!this.image) return

    this.markBroken = () => this.element.classList.add("photo--broken")
    this.image.addEventListener("error", this.markBroken)
    // An eager image can fail before this controller starts. A lazy one hasn't
    // been requested yet — it reports no size either — so it waits for the event.
    if (this.image.loading !== "lazy" && this.image.complete && this.image.naturalWidth === 0) this.markBroken()
  }

  disconnect() {
    this.image?.removeEventListener("error", this.markBroken)
  }
}
