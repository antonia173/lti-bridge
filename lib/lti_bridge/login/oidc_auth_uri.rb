require "openid_connect"

module LtiBridge
  class OIDCAuthUri
    def initialize(issuer:, client_id:, auth_url:, state:, nonce:, login_hint:, lti_message_hint:, redirect_uri:)
      @issuer = issuer,
      @client_id = client_id
      @auth_url = auth_url
      @state = state
      @nonce = nonce
      @login_hint = login_hint
      @lti_message_hint = lti_message_hint
      @redirect_uri = redirect_uri
    end

    def to_s
      OpenIDConnect::Client.new(
        identifier: @client_id,
        redirect_uri: @redirect_uri,
        host: @issuer,
        authorization_endpoint: @auth_url
      ).authorization_uri(
        scope: "openid",
        response_type: "id_token",
        response_mode: "form_post",
        prompt: "none",
        login_hint: @login_hint,
        lti_message_hint: @lti_message_hint,
        state: @state,
        nonce: @nonce
      )
    end
  end
end
