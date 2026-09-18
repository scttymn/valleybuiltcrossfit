import { Controller } from "@hotwired/stimulus"

// Day picker (mobile), class detail dialog and WOD dialogs.
export default class extends Controller {
  static targets = ["dayTab", "dayPanel", "classDialog", "wodDialog"]

  connect() {
    this.onBackdropClick = (event) => {
      if (event.target.tagName === "DIALOG") event.target.close()
    }
    this.element.addEventListener("click", this.onBackdropClick)
  }

  disconnect() {
    this.element.removeEventListener("click", this.onBackdropClick)
  }

  reset() {
    this.close()
  }

  pick({ params: { day } }) {
    this.dayTabTargets.forEach((tab, i) => tab.setAttribute("aria-selected", String(i === day)))
    this.dayPanelTargets.forEach((panel, i) => (panel.hidden = i !== day))
  }

  openClass({ params }) {
    const data = params.class
    const dialog = this.classDialogTarget
    for (const key of ["name", "when", "coach", "spots"]) {
      dialog.querySelector(`[data-field="${key}"]`).textContent = data[key]
    }
    dialog.querySelector('[data-field="url"]').href = data.url
    this.show(dialog)
  }

  openWod({ params: { day } }) {
    const dialog = this.wodDialogTargets.find((dialog) => Number(dialog.dataset.day) === day)
    if (dialog) this.show(dialog)
  }

  // Focus the dialog itself, not its first button: mobile browsers would draw
  // that button's focus ring as if someone had tabbed to it. Tab still reaches
  // the buttons, which ring as they should.
  show(dialog) {
    dialog.showModal()
    dialog.focus({ preventScroll: true })
  }

  close() {
    this.element.querySelectorAll("dialog[open]").forEach((dialog) => dialog.close())
  }
}
