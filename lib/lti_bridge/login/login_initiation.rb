require_relative "oidc_auth_uri"

module LtiBridge
  class LoginInitiation
    REQUIRED_PARAMS = %w[iss login_hint lti_message_hint target_link_uri].freeze

    def self.handle(request, auth_url)
      params = request.params
      missing = REQUIRED_PARAMS.select { |k| params[k].nil? }
      raise "Missing login params: #{missing.join(', ')}" unless missing.empty?

      state = SecureRandom.hex(16)
      nonce = SecureRandom.hex(16)

      OidcAuthUri.new(
        issuer: params["iss"],
        client_id: params["client_id"],
        auth_url: auth_url,
        state: state,
        nonce: nonce,
        login_hint: params["login_hint"],
        lti_message_hint: params["lti_message_hint"],
        redirect_uri: params["target_link_uri"]
      ).to_s
    end
  end
end
