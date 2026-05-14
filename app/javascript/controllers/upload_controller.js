import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "input", "preview", "filename", "filesize", "progress", "progressBar", "progressText", "error", "submit"]
  static values = {
    maxFileSize: { type: Number, default: 1073741824 },
    chunkSize: { type: Number, default: 94371840 },
    chunkStartUrl: String,
    chunkUrlTemplate: String,
    chunkCompleteUrlTemplate: String,
    storageRemaining: { type: Number, default: 1073741824 },
    errorTooLarge: { type: String, default: "File exceeds the maximum size of 1 GB." },
    errorQuotaExceeded: { type: String, default: "File exceeds your remaining storage quota." },
    errorInvalidFilename: { type: String, default: "Filename contains invalid characters or is too long." },
    progressPreparing: { type: String, default: "Preparing upload..." },
    progressUploading: { type: String, default: "Uploading" },
    progressProcessing: { type: String, default: "Processing file..." }
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

  async submit(event) {
    const file = this.inputTarget.files[0]
    if (!file) return

    event.preventDefault()
    event.stopImmediatePropagation()

    const error = this.validateFile(file)
    if (error) {
      this.showError(error)
      return
    }

    this.setUploading(true)
    this.showProgress(this.progressPreparingValue, 0)

    try {
      const upload = await this.startChunkedUpload(file)
      await this.uploadChunks(file, upload)
      const result = await this.completeChunkedUpload(upload.upload_id)
      window.location.href = result.redirect_url
    } catch (error) {
      this.showError(error.message)
      this.hideProgress()
      this.setUploading(false)
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

  async startChunkedUpload(file) {
    const data = new FormData(this.element)
    data.delete("file")
    data.append("filename", file.name)
    data.append("byte_size", file.size)
    data.append("content_type", file.type)

    return await this.postForm(this.chunkStartUrlValue, data)
  }

  async uploadChunks(file, upload) {
    const chunkSize = upload.chunk_size || this.chunkSizeValue
    const totalChunks = upload.total_chunks || Math.ceil(file.size / chunkSize)

    for (let index = 0; index < totalChunks; index++) {
      const start = index * chunkSize
      const chunk = file.slice(start, Math.min(start + chunkSize, file.size))
      const data = new FormData()
      data.append("index", index)
      data.append("chunk", chunk, file.name)

      await this.postForm(this.chunkUrl(upload.upload_id), data)
      this.showProgress(`${this.progressUploadingValue} ${index + 1}/${totalChunks}`, ((index + 1) / totalChunks) * 100)
    }
  }

  async completeChunkedUpload(uploadId) {
    this.showProgress(this.progressProcessingValue, 100)
    return await this.postForm(this.completeUrl(uploadId), new FormData())
  }

  async postForm(url, data) {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Accept": "application/json",
        "X-CSRF-Token": this.csrfToken()
      },
      credentials: "same-origin",
      body: data
    })
    const json = await response.json()

    if (!response.ok) {
      throw new Error((json.errors || ["Upload failed."]).join(" "))
    }

    return json
  }

  chunkUrl(uploadId) {
    return this.chunkUrlTemplateValue.replace(":id", encodeURIComponent(uploadId))
  }

  completeUrl(uploadId) {
    return this.chunkCompleteUrlTemplateValue.replace(":id", encodeURIComponent(uploadId))
  }

  csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }

  setUploading(uploading) {
    if (!this.hasSubmitTarget) return

    this.submitTarget.disabled = uploading
    this.submitTarget.classList.toggle("opacity-50", uploading)
    this.submitTarget.classList.toggle("cursor-not-allowed", uploading)
    this.submitTarget.classList.toggle("cursor-pointer", !uploading)
  }

  showProgress(text, percent) {
    if (this.hasProgressTarget) {
      this.progressTarget.classList.remove("hidden")
    }
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${Math.round(percent)}%`
    }
    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = text
    }
  }

  hideProgress() {
    if (this.hasProgressTarget) {
      this.progressTarget.classList.add("hidden")
    }
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = "0%"
    }
  }

  formatSize(bytes) {
    if (bytes === 0) return "0 Bytes"
    const k = 1024
    const sizes = ["Bytes", "KB", "MB", "GB"]
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i]
  }
}
