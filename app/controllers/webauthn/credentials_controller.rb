module Webauthn
  class CredentialsController < ApplicationController
    def new
      create_options = WebAuthn::Credential.options_for_create(
        user: {
          id: current_user.id.to_s,
          name: current_user.email_address,
          display_name: current_user.email_address
        },
        exclude: current_user.webauthn_credentials.pluck(:external_id)
      )

      session[:webauthn_creation_challenge] = create_options.challenge

      render json: create_options
    end

    def create
      webauthn_credential = WebAuthn::Credential.from_create(params[:credential])

      webauthn_credential.verify(session.delete(:webauthn_creation_challenge))

      current_user.webauthn_credentials.create!(
        external_id: Base64.strict_encode64(webauthn_credential.raw_id),
        public_key: webauthn_credential.public_key,
        nickname: params[:nickname].presence || "Passkey",
        sign_count: webauthn_credential.sign_count
      )

      render json: { status: "ok" }
    rescue WebAuthn::Error => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy
      credential = current_user.webauthn_credentials.find(params[:id])
      credential.destroy
      redirect_to profile_path, notice: t("flash.webauthn.credentials.destroy.notice")
    end
  end
end
