import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "log", "sendBtn"]
  static values = { url: String, title: String, author: String }

  #messages = []
  #source = null

  send() {
    const text = this.inputTarget.value.trim()
    if (!text || this.#source) return

    this.#addBubble("user", text)
    this.inputTarget.value = ""
    this.sendBtnTarget.disabled = true

    this.#messages.push({ role: "user", content: text })

    const bubble = this.#addThinkingBubble()
    let content = ""
    let started = false

    const params = new URLSearchParams({
      title: this.titleValue,
      author: this.authorValue,
      messages: JSON.stringify(this.#messages),
    })

    this.#source = new EventSource(`${this.urlValue}?${params}`)

    this.#source.onmessage = (e) => {
      if (e.data === "[DONE]") {
        this.#source.close()
        this.#source = null
        if (content.trim())
          this.#messages.push({ role: "assistant", content: content.trim() })
        this.sendBtnTarget.disabled = false
        this.inputTarget.focus()
        return
      }
      if (e.data.startsWith("[ERROR]")) {
        this.#source.close()
        this.#source = null
        bubble.textContent = "Couldn't connect to the AI. Try again."
        bubble.classList.remove("chat-bubble--thinking")
        this.sendBtnTarget.disabled = false
        return
      }
      content += e.data
      if (!started && content.trim()) {
        started = true
        bubble.classList.remove("chat-bubble--thinking")
        bubble.innerHTML = ""
      }
      bubble.textContent = content
    }

    this.#source.onerror = () => {
      if (!this.#source) return
      this.#source.close()
      this.#source = null
      bubble.textContent = "Connection error. Try again."
      bubble.classList.remove("chat-bubble--thinking")
      this.sendBtnTarget.disabled = false
    }
  }

  disconnect() {
    this.#source?.close()
  }

  #addBubble(role, text) {
    const el = document.createElement("p")
    el.className = `chat-bubble chat-bubble--${role === "user" ? "user" : "ai"}`
    el.textContent = text
    this.logTarget.appendChild(el)
    el.scrollIntoView({ behavior: "smooth", block: "nearest" })
    return el
  }

  #addThinkingBubble() {
    const el = document.createElement("p")
    el.className = "chat-bubble chat-bubble--ai chat-bubble--thinking"
    el.innerHTML = "<span></span><span></span><span></span>"
    this.logTarget.appendChild(el)
    el.scrollIntoView({ behavior: "smooth", block: "nearest" })
    return el
  }
}
