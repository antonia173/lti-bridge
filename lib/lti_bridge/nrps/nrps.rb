require_relative "../security/access_token"

module LtiBridge
  class NRPS
    CONTEXT_ROLES = %w[Learner Instructor Mentor ContentDeveloper].freeze

    def initialize(access_token:, memberships_url:)
      @memberships_url = memberships_url
      @access_token = access_token
    end

    def members(query: {})
      if query[:role] && !CONTEXT_ROLES.include?(query[:role])
        warn "WARNING: role '#{query[:role]}' is not a valid context-level role. Valid roles: #{CONTEXT_ROLES.join(', ')}"
      end

      response = HTTParty.get(@memberships_url, 
        headers: {
          'Authorization' => "Bearer #{@access_token}",
          'Accept' => 'application/vnd.ims.lti-nrps.v2.membershipcontainer+json'
        },
        query: query
      )

      unless response.success?
        raise "Failed to fetch membership list: #{response.code} - #{response.body}"
      end

      JSON.parse(response.body)["members"]
    end
  end
end
