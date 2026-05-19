import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

const DIMENSION_KEYS = [
  "pace",
  "emotional_weight",
  "character_depth",
  "world_building",
  "prose_complexity",
  "plot_intricacy",
  "darkness",
]

const DIMENSION_LABELS = [
  "Pace",
  "Emotional Weight",
  "Character Depth",
  "World-building",
  "Prose",
  "Plot Complexity",
  "Darkness",
]

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    dimensions: Object,
    comparison: Object,
    primaryLabel: String,
    comparisonLabel: String,
  }

  connect() {
    if (this._chart) return
    this.#initChart()
  }

  disconnect() {
    this._chart?.destroy()
    this._chart = null
  }

  #initChart() {
    const canvas = this.hasCanvasTarget ? this.canvasTarget : this.element.querySelector("canvas")
    if (!canvas) return

    const primaryData = this.#extractDimensionValues(this.dimensionsValue)
    if (!primaryData) return

    const accentColor = this.#accentColor()
    const datasets = [
      {
        label: this.primaryLabelValue || "Book",
        data: primaryData,
        backgroundColor: accentColor.fill,
        borderColor: accentColor.border,
        borderWidth: 2,
        pointRadius: 3,
      },
    ]

    const hasComparison =
      this.hasComparisonValue &&
      this.comparisonValue &&
      Object.keys(this.comparisonValue).length > 0

    if (hasComparison) {
      const comparisonData = this.#extractDimensionValues(this.comparisonValue)
      if (comparisonData) {
        datasets.push({
          label: this.comparisonLabelValue || "Comparison",
          data: comparisonData,
          backgroundColor: "rgba(156, 163, 175, 0.3)",
          borderColor: "rgba(156, 163, 175, 0.8)",
          borderWidth: 2,
          pointRadius: 3,
        })
      }
    }

    this._chart = new Chart(canvas, {
      type: "radar",
      data: {
        labels: DIMENSION_LABELS,
        datasets,
      },
      options: {
        scales: {
          r: {
            min: 0,
            max: 1,
            ticks: { display: false },
            grid: { color: "rgba(0,0,0,0.08)" },
          },
        },
        plugins: {
          legend: { display: hasComparison },
        },
        elements: {
          line: { borderWidth: 2 },
          point: { radius: 3 },
        },
      },
    })
  }

  #extractDimensionValues(dimensionsObject) {
    if (!dimensionsObject || Object.keys(dimensionsObject).length === 0) return null

    const values = DIMENSION_KEYS.map((key) => {
      const val = dimensionsObject[key]
      return typeof val === "number" ? val : 0
    })

    const hasAnyValue = values.some((v) => v > 0)
    if (!hasAnyValue) return null

    return values
  }

  #accentColor() {
    const style = getComputedStyle(document.documentElement)
    const accent = style.getPropertyValue("--color-accent").trim()

    if (accent) {
      return {
        fill: accent.replace(")", ", 0.4)").replace("rgb(", "rgba("),
        border: accent,
      }
    }

    return {
      fill: "rgba(99, 102, 241, 0.4)",
      border: "rgba(99, 102, 241, 1)",
    }
  }
}
