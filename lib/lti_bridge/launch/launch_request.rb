require_relative "launch_data"
require_relative "../security/jwt_content"

module LtiBridge
    class LaunchRequest
       attr_reader :data, :state

      def initialize(request)
        jwt = request.params[:id_token]
        raise Errors::InvalidLaunch, "Missing id_token" unless jwt

        payload = JWTContent.new(jwt).id_token
        
        @data = LaunchData.new(payload)
        @state = SecureRandom.uuid
      end

    end
end
