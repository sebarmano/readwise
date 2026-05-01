import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "output"]
  static values = { url: String }

  start() {
    this.#setLoading(true)
    this.outputTarget.textContent = ""
    this._done = false

    this._source = new EventSource(this.#buildUrl())
    this._source.onmessage = (e) => this.#handle(e.data)
    this._source.onerror = () => this.#onError()
  }

  disconnect() {
    this._source?.close()
  }

  #handle(data) {
    this._done = true
    if (data === "[DONE]") {
      this._source.close()
      this.#setLoading(false)
      Turbo.visit(window.location.href, { frame: "tab-queue" })
      return
    }
    if (data.startsWith("[ERROR]")) {
      this._source.close()
      this.#setLoading(false)
      this.outputTarget.textContent = data.replace("[ERROR] ", "")
      return
    }
    this.outputTarget.textContent += data
  }

  #onError() {
    if (this._done) return
    this._source?.close()
    this.#setLoading(false)
    this.outputTarget.textContent = "Could not connect to the server."
  }

  #setLoading(loading) {
    this.buttonTarget.disabled = loading
    this.buttonTarget.textContent = loading
      ? "Generating…"
      : "Get Recommendations"
  }

  #buildUrl() {
    const clarification = this.element
      .querySelector("[data-clarification]")
      ?.value?.trim()
    return clarification
      ? `${this.urlValue}?clarification=${encodeURIComponent(clarification)}`
      : this.urlValue
  }
}
