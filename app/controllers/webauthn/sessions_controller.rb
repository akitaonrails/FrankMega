module Webauthn
  class SessionsController < ApplicationController
    allow_unauthenticated_access

    def new
      normalized_email = params[:email_address].to_s.strip.downcase
      user = User.find_by(email_address: normalized_email)

      # Always return options regardless of whether user exists or has passkeys.
      # This prevents email enumeration — attacker can't distinguish
      # "no such user" from "user has no passkeys".
      credential_ids = user&.webauthn_credentials&.pluck(:external_id)&.first(5) || []
      # Always pad the allow list to five IDs to prevent credential-count enumeration.
      credential_ids += dummy_credential_ids(normalized_email, 5 - credential_ids.length)

      get_options = WebAuthn::Credential.options_for_get(allow: credential_ids, user_verification: "required")
      session[:webauthn_authentication_challenge] = get_options.challenge

      render json: get_options
    end

    def create
      webauthn_credential = WebAuthn::Credential.from_get(params[:credential])

      stored_credential = WebauthnCredential.find_by!(
        external_id: Base64.strict_encode64(webauthn_credential.raw_id)
      )

      webauthn_credential.verify(
        session.delete(:webauthn_authentication_challenge),
        public_key: stored_credential.public_key,
        sign_count: stored_credential.sign_count,
        user_verification: true
      )

      stored_credential.update!(sign_count: webauthn_credential.sign_count)

      user = stored_credential.user

      if user.banned?
        render json: { error: t("flash.webauthn.sessions.create.account_suspended") }, status: :forbidden
      else
        start_new_session_for user
        render json: { status: "ok", redirect_to: after_authentication_url }
      end
    rescue WebAuthn::Error, ActiveRecord::RecordNotFound, NoMethodError
      render json: { error: t("flash.webauthn.sessions.create.invalid_credential") }, status: :unprocessable_entity
    end

    private

    def dummy_credential_ids(email_address, count)
      count.times.map do |index|
        Base64.strict_encode64(Digest::SHA256.digest("#{email_address}:#{index}"))
      end
    end
  end
end
