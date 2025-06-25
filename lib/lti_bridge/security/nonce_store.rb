module LtiBridge
  class NonceStore
    EXPIRATION = 5.minutes

    def self.validate(nonce, client_id)
      key = cache_key(nonce, client_id)
      return false if Cache.exist?(key)

      Cache.write(key, true, expires_in: EXPIRATION)
      true
    end

    def self.cache_key(nonce, client_id)
      "lti_nonce:#{client_id}:#{nonce}"
    end
  end
end

