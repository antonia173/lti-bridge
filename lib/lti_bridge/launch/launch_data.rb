module LtiBridge
    class LaunchData
      attr_reader :user_id, :version, :deployment_id, :target_link_uri,
                  :resource_link, :roles, :context, :tool_platform,
                  :custom, :launch_presentation, :lis,
                  :name, :given_name, :family_name, :middle_name, :picture, :email, :locale,
                  :audience, :expiration_time, :issued_time, :azp, :nonce, :issuer, :raw_payload,
                  :message_type, :deep_linking_settings,
                  :ags_endpoint, :ags_lineitems, :ags_scope,
                  :nrps_context_memberships_url, :nrps_version, :nrps_scope

      REQUIRED_KEYS = [
        "sub",
        "https://purl.imsglobal.org/spec/lti/claim/version",
        "https://purl.imsglobal.org/spec/lti/claim/deployment_id",
        "https://purl.imsglobal.org/spec/lti/claim/target_link_uri",
        "https://purl.imsglobal.org/spec/lti/claim/resource_link",
        "https://purl.imsglobal.org/spec/lti/claim/roles"
      ].freeze

      def self.build(payload)
        missing = REQUIRED_KEYS.select { |key| payload[key].nil? }
        raise Errors::InvalidLaunch, "Missing required claims: #{missing.join(', ')}" unless missing.empty?

        new(payload)
      end

      def initialize(payload)
        @raw_payload = payload

        # Required
        @user_id = payload["sub"]
        @version = payload["https://purl.imsglobal.org/spec/lti/claim/version"]
        @deployment_id = payload["https://purl.imsglobal.org/spec/lti/claim/deployment_id"]
        @target_link_uri = payload["https://purl.imsglobal.org/spec/lti/claim/target_link_uri"]
        @resource_link = payload["https://purl.imsglobal.org/spec/lti/claim/resource_link"]
        @roles = payload["https://purl.imsglobal.org/spec/lti/claim/roles"]

        # Required by OIDC
        @issuer = payload["iss"]
        @audience = payload["aud"]
        @expiration_time = payload["exp"]
        @issued_time = payload["iat"]
        @azp = payload["azp"]
        @nonce = payload["nonce"]

        # Optional
        @context = payload["https://purl.imsglobal.org/spec/lti/claim/context"] || {}
        @tool_platform = payload["https://purl.imsglobal.org/spec/lti/claim/tool_platform"] || {}
        @launch_presentation = payload["https://purl.imsglobal.org/spec/lti/claim/launch_presentation"] || {}
        @lis = payload["https://purl.imsglobal.org/spec/lti/claim/lis"] || {}
        @custom = payload["https://purl.imsglobal.org/spec/lti/claim/custom"] || {}

        # User Identity
        @name = payload["name"]
        @given_name = payload["given_name"]
        @family_name = payload["family_name"]
        @middle_name = payload["middle_name"]
        @picture = payload["picture"]
        @email = payload["email"]
        @locale = payload["locale"]

        # Deep Linking
        @message_type = payload["https://purl.imsglobal.org/spec/lti/claim/message_type"]
        @deep_linking_settings = payload["https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings"] || {}
        @deep_linking_return_url = @deep_linking_settings["deep_link_return_url"]

        # AGS
        @ags_endpoint = payload["https://purl.imsglobal.org/spec/lti-ags/claim/endpoint"] || {}
        @ags_lineitems = @ags_endpoint["lineitems"]
        @ags_scope = @ags_endpoint["scope"] || []

        # NRPS
        @nrps = payload["https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice"] || {}
        @nrps_context_memberships_url = @nrps["context_memberships_url"]
        @nrps_version = @nrps["service_versions"] || []
        @nrps_scope = "https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly"

      end

      def deep_linking_request?
        @message_type == "LtiDeepLinkingRequest"
      end

      def ags?
        @ags_endpoint.is_a?(Hash) && @ags_endpoint.any?
      end

      def nrps?
        @nrps.any?
      end

      def custom?
        @custom.is_a?(Hash) && @custom.any?
      end

      def instructor?
        roles.any? do |role|
          role.start_with?("http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor") ||
          role.start_with?("http://purl.imsglobal.org/vocab/lis/v2/membership/Instructor") ||
          role.start_with?("http://purl.imsglobal.org/vocab/lis/v2/institution/person#Instructor")

        end
      end

      def learner?
        roles.any? do |role|
          role.start_with?("http://purl.imsglobal.org/vocab/lis/v2/membership#Learner") ||
          role.start_with?("http://purl.imsglobal.org/vocab/lis/v2/membership/Learner") ||
          role.start_with?("http://purl.imsglobal.org/vocab/lis/v2/institution/person#Learner") ||
          role.start_with?("http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student")
        end
      end

      def administrator?
        roles.any? do |role|
          role.start_with?("http://purl.imsglobal.org/vocab/lis/v2/membership#Administrator") ||
          role.start_with?("http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator") ||
          role.start_with?("http://purl.imsglobal.org/vocab/lis/v2/system/person#Administrator")
        end
      end

    end
end
