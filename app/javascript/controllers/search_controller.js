import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input"];

  connect() {
    // Refocus input after Turbo frame updates
    document.addEventListener("turbo:frame-load", this.refocusInput.bind(this));
  }

  disconnect() {
    document.removeEventListener(
      "turbo:frame-load",
      this.refocusInput.bind(this),
    );
  }

  search() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.saveCaretPosition();
      this.element.requestSubmit();
    }, 300);
  }

  submitAndRefocus(event) {
    event.preventDefault();
    this.saveCaretPosition();
    this.element.requestSubmit();
  }

  saveCaretPosition() {
    if (this.hasInputTarget) {
      this.caretPosition = this.inputTarget.selectionStart;
    }
  }

  refocusInput() {
    if (this.hasInputTarget) {
      this.inputTarget.focus();
      // Restore caret position if we have one
      if (this.caretPosition !== undefined) {
        const pos = Math.min(this.caretPosition, this.inputTarget.value.length);
        this.inputTarget.setSelectionRange(pos, pos);
      }
    }
  }
}
