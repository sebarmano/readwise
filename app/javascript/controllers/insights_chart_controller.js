import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

export default class extends Controller {
  static values = { genres: Object }

  connect() {
    if (this._chart) return
    this.#initChart()
  }

  disconnect() {
    this._chart?.destroy()
    this._chart = null
  }

  #initChart() {
    const canvas = this.element.querySelector("canvas")
    if (!canvas) return

    const labels = Object.keys(this.genresValue)
    const data = Object.values(this.genresValue)

    this._chart = new Chart(canvas, {
      type: "bar",
      data: {
        labels,
        datasets: [
          {
            data,
            backgroundColor: labels.map(
              (_, i) => `hsla(${(i * 47) % 360}, 55%, 58%, 0.85)`,
            ),
            borderRadius: 4,
            borderSkipped: false,
          },
        ],
      },
      options: {
        indexAxis: "y",
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { display: false }, ticks: { precision: 0 } },
          y: { grid: { display: false } },
        },
      },
    })
  }
}
