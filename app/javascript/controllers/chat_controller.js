import { Controller } from "@hotwired/stimulus"

const MAX_TURNS = 10

export default class extends Controller {
  static targets = [
    "input",
    "chat",
    "answerInput",
    "feedbackInput",
    "inputRow",
    "answerRow",
    "feedbackRow",
  ]
  static values = { questionUrl: String, recommendUrl: String }

  #state = "idle"
  #messages = [] // [{role: "assistant"|"user", content: "..."}]
  #clarification = ""
  #turns = 0
  #source = null

  ask() {
    if (this.#state !== "idle") return
    this.#clarification = this.inputTarget.value.trim()
    if (this.#clarification) this.#addBubble("user", this.#clarification)
    this.#transition("questioning")
    this.#streamTurn()
  }

  send() {
    if (this.#state !== "answering") return
    const answer = this.answerInputTarget.value.trim()
    if (!answer) return
    this.#addBubble("user", answer)
    this.answerInputTarget.value = ""
    this.#messages.push({ role: "user", content: answer })
    this.#transition("questioning")
    this.#streamTurn()
  }

  refine() {
    if (this.#state !== "reviewing") return
    const feedback = this.feedbackInputTarget.value.trim()
    if (!feedback) return
    this.#addBubble("user", feedback)
    this.feedbackInputTarget.value = ""
    this.#messages.push({ role: "user", content: feedback })
    this.#turns = 0
    this.#transition("questioning")
    this.#streamTurn()
  }

  finish() {
    this.#transition("done")
  }

  reset() {
    this.#source?.close()
    this.chatTarget.innerHTML = ""
    this.#messages = []
    this.#clarification = ""
    this.#turns = 0
    this.inputTarget.value = ""
    this.#transition("idle")
  }

  disconnect() {
    this.#source?.close()
  }

  #streamTurn() {
    const bubble = this.#addThinkingBubble()
    let content = ""
    let started = false

    const params = new URLSearchParams()
    if (this.#clarification) params.set("clarification", this.#clarification)
    if (this.#messages.length)
      params.set("messages", JSON.stringify(this.#messages))

    this.#source = new EventSource(`${this.questionUrlValue}?${params}`)
    this.#source.onmessage = (e) => {
      if (e.data === "[DONE]") {
        this.#source.close()
        this.#handleTurnComplete(bubble, content)
        return
      }
      if (e.data.startsWith("[ERROR]")) {
        this.#source.close()
        bubble.textContent = "Sorry, couldn't connect. Try again."
        bubble.classList.remove("chat-bubble--thinking")
        this.#transition("idle")
        return
      }
      content += e.data
      if (!started && content.trim()) {
        started = true
        bubble.classList.remove("chat-bubble--thinking")
        bubble.innerHTML = ""
      }
      if (content.trim() !== "[READY]") bubble.textContent = content
    }
    this.#source.onerror = () => {
      if (this.#state !== "questioning") return
      this.#source.close()
      bubble.textContent = "Connection error. Try again."
      this.#transition("idle")
    }
  }

  #handleTurnComplete(bubble, content) {
    if (content.trim() === "[READY]" || this.#turns >= MAX_TURNS) {
      bubble.remove()
      this.#transition("recommending")
      this.#streamRecommendations()
    } else {
      this.#turns++
      this.#messages.push({ role: "assistant", content: content.trim() })
      this.#transition("answering")
      this.answerInputTarget.focus()
    }
  }

  #streamRecommendations() {
    const bubble = this.#addThinkingBubble()
    const params = new URLSearchParams()
    if (this.#clarification) params.set("clarification", this.#clarification)
    if (this.#messages.length)
      params.set("messages", JSON.stringify(this.#messages))

    this.#source = new EventSource(`${this.recommendUrlValue}?${params}`)
    this.#source.onmessage = (e) => {
      if (e.data === "[DONE]") {
        this.#source.close()
        bubble.classList.remove("chat-bubble--thinking")
        bubble.textContent = "Added to your queue ↓"
        bubble.classList.add("chat-bubble--done")
        Turbo.visit(window.location.href, { frame: "tab-queue" })
        this.#transition("reviewing")
        this.#addBubble(
          "ai",
          "What do you think? I can refine these if needed — just tell me what to change.",
        )
        this.feedbackInputTarget.focus()
        return
      }
      if (e.data.startsWith("[ERROR]")) {
        this.#source.close()
        bubble.classList.remove("chat-bubble--thinking")
        bubble.textContent = e.data.replace("[ERROR] ", "")
        this.#transition("idle")
        return
      }
    }
    this.#source.onerror = () => {
      if (this.#state !== "recommending") return
      this.#source.close()
      bubble.textContent = "Connection error. Try again."
      this.#transition("idle")
    }
  }

  #transition(state) {
    this.#state = state
    this.element.dataset.chatState = state
  }

  #addBubble(role, text) {
    const el = document.createElement("p")
    el.className = `chat-bubble chat-bubble--${role}`
    el.textContent = text
    this.chatTarget.appendChild(el)
    el.scrollIntoView({ behavior: "smooth", block: "nearest" })
    return el
  }

  #addThinkingBubble() {
    const el = document.createElement("p")
    el.className = "chat-bubble chat-bubble--ai chat-bubble--thinking"
    el.innerHTML = "<span></span><span></span><span></span>"
    this.chatTarget.appendChild(el)
    el.scrollIntoView({ behavior: "smooth", block: "nearest" })
    return el
  }
}
