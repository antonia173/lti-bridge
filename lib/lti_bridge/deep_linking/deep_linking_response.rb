require "json/jwt"
require "securerandom"

require_relative "../security/jwk"

module LtiBridge
    class DeepLinkingResponse
      def initialize(launch_data:, content_items:)
        @launch_data = launch_data
        @content_items = content_items
      end

      def form_html
        <<~HTML
          <form id="deep_link_response_form" action="#{return_url}" method="POST">
            <input type="hidden" name="JWT" value="#{jwt}">
          </form>
          <script>document.getElementById('deep_link_response_form').submit();</script>
        HTML
      end

      def return_url
        @launch_data.deep_linking_settings["deep_link_return_url"]
      end

      private

      def jwt
        payload = {
          iss: @launch_data.audience,
          aud: @launch_data.issuer,
          azp: @launch_data.issuer,
          nonce: SecureRandom.hex(16),
          iat: Time.now.to_i,
          exp: (Time.now + 10.minutes).to_i,
          "https://purl.imsglobal.org/spec/lti/claim/deployment_id": @launch_data.deployment_id,
          "https://purl.imsglobal.org/spec/lti/claim/message_type": "LtiDeepLinkingResponse",
          "https://purl.imsglobal.org/spec/lti/claim/version": "1.3.0",
          "https://purl.imsglobal.org/spec/lti-dl/claim/content_items": @content_items,
          "https://purl.imsglobal.org/spec/lti-dl/claim/data": @launch_data.deep_linking_settings["data"]
        }.compact

        jwk = Jwk.new
        jwt = JSON::JWT.new(payload)
        jwt.header[:kid] = jwk.kid
        jwt.sign(jwk.private_key, :RS256).to_s
      end
    end
end
