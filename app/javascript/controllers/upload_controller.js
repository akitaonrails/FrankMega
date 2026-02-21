import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "input", "preview", "filename", "filesize", "progress", "progressBar", "progressText"]

  dragover(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("border-primary", "bg-red-50", "dark:bg-red-900/10")
  }

  dragenter(event) {
    event.preventDefault()
  }

  dragleave(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-primary", "bg-red-50", "dark:bg-red-900/10")
  }

  drop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-primary", "bg-red-50", "dark:bg-red-900/10")

    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.inputTarget.files = files
      this.showPreview(files[0])
    }
  }

  fileSelected() {
    const file = this.inputTarget.files[0]
    if (file) {
      this.showPreview(file)
    }
  }

  showPreview(file) {
    this.previewTarget.classList.remove("hidden")
    this.filenameTarget.textContent = file.name
    this.filesizeTarget.textContent = this.formatSize(file.size)
  }

  formatSize(bytes) {
    if (bytes === 0) return "0 Bytes"
    const k = 1024
    const sizes = ["Bytes", "KB", "MB", "GB"]
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i]
  }
}
