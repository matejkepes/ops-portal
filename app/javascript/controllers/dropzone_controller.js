import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropzone"
export default class extends Controller {
  static targets = ["input"]
  static classes = ["active"]

  dragover(event) {
    if (!this.isFileDrag(event)) return;

    event.preventDefault();
    if (!this.isUploading) this.element.classList.add(this.activeClass);
  }

  dragleave(event) {
    if (!this.element.contains(event.relatedTarget)) this.element.classList.remove(this.activeClass);
  }

  drop(event) {
    event.preventDefault();
    this.element.classList.remove(this.activeClass);
    if (this.isUploading) return;

    this.inputTarget.files = event.dataTransfer.files;
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }));
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }));
  }

  preventOpeningFile(event) {
    if (this.isFileDrag(event)) event.preventDefault();
  }

  isFileDrag(event) {
    return event.dataTransfer.types.includes("Files");
  }

  get isUploading() {
    return this.inputTarget.form.getAttribute("aria-busy") === "true";
  }
}
