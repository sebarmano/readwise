import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["title", "author", "year", "results"]

  async lookup() {
    const q = this.titleTarget.value.trim()
    if (!q) return

    const response = await fetch(`/books/search?q=${encodeURIComponent(q)}`, {
      headers: { Accept: "application/json" }
    })
    const results = await response.json()
    this.#renderResults(results)
  }

  select(event) {
    const { title, author, year } = event.params
    this.titleTarget.value = title || ""
    this.authorTarget.value = author || ""
    if (year) this.yearTarget.value = year
    this.resultsTarget.innerHTML = ""
  }

  #renderResults(results) {
    if (!results.length) {
      this.resultsTarget.innerHTML = '<p class="lookup-empty">No results found.</p>'
      return
    }
    this.resultsTarget.innerHTML = results.map(r => this.#resultButton(r)).join("")
  }

  #resultButton(r) {
    const title = this.#esc(r.title || "")
    const author = this.#esc(r.author || "")
    const year = r.year || ""
    const meta = [author, year].filter(Boolean).join(" · ")
    return `<button type="button" class="lookup-result"
      data-action="click->book-lookup#select"
      data-book-lookup-title-param="${title}"
      data-book-lookup-author-param="${author}"
      data-book-lookup-year-param="${year}">
      <span class="lookup-title">${title}</span>
      <span class="lookup-meta">${this.#esc(meta)}</span>
    </button>`
  }

  #esc(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
