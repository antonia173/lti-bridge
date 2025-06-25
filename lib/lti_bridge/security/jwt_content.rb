require "json/jwt"
require_relative "nonce_store"

module LtiBridge
    class JWTContent
      attr_reader :id_token_string

      def initialize(id_token_string)
        @id_token_string = id_token_string
      end

      def id_token
        validate!
      end


      private

      def validate!
        jwt, issuer, platform = decode_id_token

        raise "Invalid issuer" unless jwt["iss"] == issuer
        raise "Invalid audience" unless [jwt["aud"]].flatten.include?(platform[:client_id])
        raise "Invalid azp" if jwt["azp"] && jwt["azp"] != platform[:client_id]
        raise "Token expired" unless jwt["exp"] && Time.at(jwt["exp"]) > Time.now
        raise "Invalid issue time" unless jwt["iat"] && Time.at(jwt["iat"]).between?(5.minutes.ago, Time.now)
        raise "Invalid or reused nonce" unless jwt["nonce"] && NonceStore.validate(jwt["nonce"], platform[:client_id])

        jwt
      end


      def decode_id_token
        unverified = JSON::JWT.decode(@id_token_string, :skip_verification)
        issuer = unverified["iss"]
        kid = unverified.header[:kid]

        platform = Platform.find_by(issuer: issuer)
        raise "Unknown platform: #{issuer}" unless platform

        jwk_set = fetch_jwk(uri: platform.jwks_url, kid: kid)
        jwt = JSON::JWT.decode(@id_token_string, jwk_set).as_json

        [jwt, issuer, platform]
      end

      def fetch_jwk(uri:, kid: nil)
        @jwk_cache ||= {}   
        @jwk_cache[uri] ||= JSON::JWK::Set::Fetcher.fetch(uri, kid: kid, auto_detect: false)
      end

    end
end