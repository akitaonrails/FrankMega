import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    challengeUrl: String,
    prompt: { type: String, default: "Give this passkey a name:" },
    defaultName: { type: String, default: "My Passkey" },
    registerFailed: { type: String, default: "Failed to register passkey: " },
    authFailed: { type: String, default: "Authentication failed: " },
    unknownError: { type: String, default: "Unknown error" }
  }

  async register() {
    try {
      const response = await fetch("/webauthn/credentials/new", {
        headers: { "Accept": "application/json", "X-CSRF-Token": this.csrfToken }
      })
      const options = await response.json()

      // Convert base64url to ArrayBuffer
      options.challenge = this.base64urlToBuffer(options.challenge)
      options.user.id = this.base64urlToBuffer(options.user.id)
      if (options.excludeCredentials) {
        options.excludeCredentials = options.excludeCredentials.map(cred => ({
          ...cred,
          id: this.base64urlToBuffer(cred.id)
        }))
      }

      const credential = await navigator.credentials.create({ publicKey: options })

      const nickname = prompt(this.promptValue, this.defaultNameValue)
      if (!nickname) return

      const createResponse = await fetch("/webauthn/credentials", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({
          credential: this.serializeCredential(credential),
          nickname: nickname
        })
      })

      if (createResponse.ok) {
        window.location.reload()
      } else {
        const error = await createResponse.json()
        alert(this.registerFailedValue + (error.error || this.unknownErrorValue))
      }
    } catch (e) {
      if (e.name !== "NotAllowedError") {
        console.error("WebAuthn registration error:", e)
      }
    }
  }

  async authenticate() {
    try {
      const emailInput = document.querySelector("[data-webauthn-target='email']")
      const email = emailInput ? emailInput.value : ""

      const response = await fetch(`/webauthn/session/new?email_address=${encodeURIComponent(email)}`, {
        headers: { "Accept": "application/json", "X-CSRF-Token": this.csrfToken }
      })
      const options = await response.json()

      options.challenge = this.base64urlToBuffer(options.challenge)
      if (options.allowCredentials) {
        options.allowCredentials = options.allowCredentials.map(cred => ({
          ...cred,
          id: this.base64urlToBuffer(cred.id)
        }))
      }

      const credential = await navigator.credentials.get({ publicKey: options })

      const authResponse = await fetch("/webauthn/session", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({
          credential: this.serializeCredential(credential)
        })
      })

      const result = await authResponse.json()
      if (authResponse.ok && result.redirect_to) {
        window.location.href = result.redirect_to
      } else {
        alert(this.authFailedValue + (result.error || this.unknownErrorValue))
      }
    } catch (e) {
      if (e.name !== "NotAllowedError") {
        console.error("WebAuthn authentication error:", e)
      }
    }
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }

  base64urlToBuffer(base64url) {
    const base64 = base64url.replace(/-/g, "+").replace(/_/g, "/")
    const padding = "=".repeat((4 - base64.length % 4) % 4)
    const binary = atob(base64 + padding)
    return Uint8Array.from(binary, c => c.charCodeAt(0)).buffer
  }

  bufferToBase64url(buffer) {
    const bytes = new Uint8Array(buffer)
    let binary = ""
    bytes.forEach(b => binary += String.fromCharCode(b))
    return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")
  }

  serializeCredential(credential) {
    const response = credential.response
    const data = {
      id: credential.id,
      rawId: this.bufferToBase64url(credential.rawId),
      type: credential.type,
      response: {}
    }

    if (response.attestationObject) {
      data.response.attestationObject = this.bufferToBase64url(response.attestationObject)
      data.response.clientDataJSON = this.bufferToBase64url(response.clientDataJSON)
    }

    if (response.authenticatorData) {
      data.response.authenticatorData = this.bufferToBase64url(response.authenticatorData)
      data.response.clientDataJSON = this.bufferToBase64url(response.clientDataJSON)
      data.response.signature = this.bufferToBase64url(response.signature)
      if (response.userHandle) {
        data.response.userHandle = this.bufferToBase64url(response.userHandle)
      }
    }

    return data
  }
}
