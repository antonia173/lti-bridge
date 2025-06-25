module LtiBridge
  class Cache
    class << self
      attr_accessor :store

      def write(key, value, expires_in:)
        raise "No cache store configured" unless store
        store.write(key, value, expires_in: expires_in)
      end

      def read(key)
        raise "No cache store configured" unless store
        store.read(key)
      end

      def exist?(key)
        raise "No cache store configured" unless store
        store.exist?(key)
      end
    end
  end
end
