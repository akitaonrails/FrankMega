module Webauthn
  class SessionsController < ApplicationController
    allow_unauthenticated_access

    def new
      get_options = WebAuthn::Credential.options_for_get(
        allow: WebauthnCredential.where(
          user: User.find_by(email_address: params[:email_address])
        ).pluck(:external_id)
      )

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
        sign_count: stored_credential.sign_count
      )

      stored_credential.update!(sign_count: webauthn_credential.sign_count)

      user = stored_credential.user

      if user.banned?
        render json: { error: "Account suspended." }, status: :forbidden
        return
      end

      start_new_session_for user
      render json: { status: "ok", redirect_to: after_authentication_url }
    rescue WebAuthn::Error => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
