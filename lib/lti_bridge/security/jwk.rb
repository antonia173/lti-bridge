require "json/jwk"
require "openssl"

module LtiBridge
    class Jwk
      def initialize
        @private_key_pem = ENV.fetch("SSL_JWK_PRIVATE_KEY").gsub("\\n", "\n")
        @private_key = OpenSSL::PKey::RSA.new(@private_key_pem)
        @public_key = @private_key.public_key
        @jwk = JSON::JWK.new(@public_key)
      end

      def self.build_from_env
        new.build
      end

      def build
        {
          kty: @jwk[:kty],
          alg: "RS256",
          kid: kid,
          use: "sig",
          e: @jwk[:e],
          n: @jwk[:n]
        }
      end

      def kid
        @jwk[:kid]
      end

      def public_key
        @public_key
      end

      def private_key
        @private_key
      end
    end
end
