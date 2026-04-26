import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "ratingInput", "genreInput"]

  connect() {
    this.#restoreFromUrl()
  }

  setRating(event) {
    this.ratingInputTarget.value = event.currentTarget.dataset.value
    this.#activateChip(event.currentTarget, "rating")
    this.formTarget.requestSubmit()
  }

  setGenre(event) {
    this.genreInputTarget.value = event.currentTarget.dataset.value
    this.#activateChip(event.currentTarget, "genre")
    this.formTarget.requestSubmit()
  }

  #activateChip(chip, group) {
    this.element
      .querySelectorAll(`[data-filter-group="${group}"]`)
      .forEach((el) => {
        el.classList.toggle("active", el === chip)
      })
  }

  #restoreFromUrl() {
    const params = new URLSearchParams(window.location.search)
    const rating = params.get("rating") || ""
    const genre = params.get("genre") || ""

    this.element
      .querySelectorAll("[data-filter-group='rating']")
      .forEach((chip) => {
        chip.classList.toggle("active", chip.dataset.value === rating)
      })
    this.element
      .querySelectorAll("[data-filter-group='genre']")
      .forEach((chip) => {
        chip.classList.toggle("active", chip.dataset.value === genre)
      })
  }
}
