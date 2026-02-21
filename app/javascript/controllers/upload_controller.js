import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "input", "preview", "filename", "filesize", "progress", "progressBar", "progressText", "error", "submit"]
  static values = {
    maxFileSize: { type: Number, default: 1073741824 },
    storageRemaining: { type: Number, default: 1073741824 },
    errorTooLarge: { type: String, default: "File exceeds the maximum size of 1 GB." },
    errorQuotaExceeded: { type: String, default: "File exceeds your remaining storage quota." },
    errorInvalidFilename: { type: String, default: "Filename contains invalid characters or is too long." }
  }

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
      this.handleFile(files[0])
    }
  }

  fileSelected() {
    const file = this.inputTarget.files[0]
    if (file) {
      this.handleFile(file)
    }
  }

  handleFile(file) {
    const error = this.validateFile(file)
    if (error) {
      this.showError(error)
      this.hidePreview()
    } else {
      this.hideError()
      this.showPreview(file)
    }
  }

  validateFile(file) {
    if (this.isInvalidFilename(file.name)) {
      return this.errorInvalidFilenameValue
    }

    if (file.size > this.maxFileSizeValue) {
      return this.errorTooLargeValue
    }

    if (file.size > this.storageRemainingValue) {
      return this.errorQuotaExceededValue
    }

    return null
  }

  isInvalidFilename(name) {
    if (new Blob([name]).size > 255) return true

    // eslint-disable-next-line no-control-regex
    if (/[\x00-\x1f\x7f/:*?"<>|\\]/.test(name)) return true

    return false
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    }
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      this.submitTarget.classList.add("opacity-50", "cursor-not-allowed")
      this.submitTarget.classList.remove("cursor-pointer")
    }
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = ""
      this.errorTarget.classList.add("hidden")
    }
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = false
      this.submitTarget.classList.remove("opacity-50", "cursor-not-allowed")
      this.submitTarget.classList.add("cursor-pointer")
    }
  }

  hidePreview() {
    this.previewTarget.classList.add("hidden")
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
