import { Controller } from "@hotwired/stimulus"

// Keeps each color picker and its hex field in step, and redraws the sample
// beside them as colors change. The sample is rendered by the server with the
// real Theme, so nothing here works out colors — it only passes them along.
export default class extends Controller {
  static targets = ["swatch", "hex", "setting", "frame"]
  static values = { url: String }

  picked(event) {
    this.hexFor(event.target.dataset.part).value = event.target.value
    this.refresh()
  }

  typed(event) {
    const value = event.target.value.trim()
    const hex = value.startsWith("#") ? value : `#${value}`
    // A half-typed color leaves the picker alone; the server ignores it too.
    if (/^#[0-9a-f]{6}$/i.test(hex)) this.swatchFor(event.target.dataset.part).value = hex.toLowerCase()
    this.refresh()
  }

  // From "Use this" in the sample. Only our own origin may set a color.
  suggested(event) {
    if (event.origin !== window.location.origin || !event.data?.themeSuggestion) return

    const { part, color } = event.data.themeSuggestion
    if (!/^#[0-9a-f]{6}$/.test(color) || !this.hexFor(part)) return
    this.hexFor(part).value = color
    this.swatchFor(part).value = color
    this.refresh()
  }

  refresh() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => {
      const fields = [...this.hexTargets, ...this.settingTargets]
      const params = new URLSearchParams(fields.map((field) => [field.dataset.part, field.value]))
      this.frameTarget.src = `${this.urlValue}?${params}`
    }, 150)
  }

  hexFor(part) { return this.hexTargets.find((field) => field.dataset.part === part) }
  swatchFor(part) { return this.swatchTargets.find((field) => field.dataset.part === part) }
}
