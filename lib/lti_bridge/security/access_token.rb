require "json/jwt"
require "securerandom"
require "httparty"

require_relative "jwk"

module LtiBridge
  class AccessToken

    def self.fetch(client_id:, token_url:, scope:)
      new(client_id: client_id, token_url: token_url, scope: scope).fetch
    end

    def initialize(client_id:, token_url:, scope:)
      @client_id = client_id
      @token_url = token_url
      @scope = Array(scope)
    end

    def fetch
      response = HTTParty.post(@token_url,
        headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
        body: {
          grant_type: 'client_credentials',
          client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
          client_assertion: self.jwt,
          scope: @scope.join(' ')
        }
      )

      JSON.parse(response.body)["access_token"]
    end

    def jwt
      jwt = JSON::JWT.new(
        iss: @client_id,
        sub: @client_id,
        aud: @token_url,
        iat: Time.now.to_i,
        exp: (Time.now + 10.minutes).to_i,
        jti: SecureRandom.uuid
      )

      jwk = Jwk.new
      jwt.header[:kid] = jwk.kid
      jwt.sign(jwk.private_key, :RS256).to_s
    end
  end
end
