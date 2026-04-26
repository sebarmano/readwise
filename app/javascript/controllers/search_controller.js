import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this._timer = null
  }

  submit() {
    clearTimeout(this._timer)
    this._timer = setTimeout(() => this.formTarget.requestSubmit(), 180)
  }
}
