import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "label", "hint"]

  open(event) {
    if (event.target === this.inputTarget) return
    this.inputTarget.click()
  }

  pick(event) {
    const file = event.target.files[0]
    if (file) this.#showFile(file)
  }

  dragover(event) {
    event.preventDefault()
    this.element.classList.add("drop-zone--over")
  }

  dragleave(event) {
    if (!this.element.contains(event.relatedTarget)) {
      this.element.classList.remove("drop-zone--over")
    }
  }

  drop(event) {
    event.preventDefault()
    this.element.classList.remove("drop-zone--over")

    const file = event.dataTransfer.files[0]
    if (!file) return

    const dt = new DataTransfer()
    dt.items.add(file)
    this.inputTarget.files = dt.files
    this.#showFile(file)
  }

  #showFile(file) {
    this.labelTarget.textContent = file.name
    this.hintTarget.textContent = `${(file.size / 1024).toFixed(1)} KB — ready to import`
    this.element.classList.add("drop-zone--has-file")
  }
}
