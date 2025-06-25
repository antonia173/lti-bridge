module LtiBridge
    class ToolConfiguration
      DEFAULT_CLAIMS = ["iss", "sub"]
      NRPS_SCOPE = "https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly"
      AGS_GRADE_SCOPE = "https://purl.imsglobal.org/spec/lti-ags/scope/score https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly"
      AGS_GRADE_COLUMN_SCOPE = "https://purl.imsglobal.org/spec/lti-ags/scope/score https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"

      def initialize(initiate_login_url:, jwks_url:, redirect_uris:, tool_name: "LTI Tool", root_url:,
                    logo_uri: nil, policy_uri: nil, tos_uri: nil, contact_emails: [], tool_description: nil,
                    custom_params: {}, messages: [], share_user_name: false, share_email: false,
                    nrps: false, ags_grade_sync: false, ags_grade_sync_column_mngmt: false)
        @initiate_login_url = initiate_login_url
        @jwks_url = jwks_url
        @redirect_uris = redirect_uris
        @tool_name = tool_name
        @root_url = root_url
        @logo_uri = logo_uri
        @contact_emails = contact_emails
        @tool_description = tool_description
        @custom_params = custom_params
        @messages = messages

        @claims = DEFAULT_CLAIMS
        @claims += ["name", "given_name", "family_name"] if share_user_name
        @claims += ["email"] if share_email

        @scope = []
        @scope << NRPS_SCOPE if nrps
        @scope << AGS_GRADE_SCOPE if ags_grade_sync
        @scope << AGS_GRADE_COLUMN_SCOPE if ags_grade_sync_column_mngmt
        @scope = @scope.any? ? @scope.join(" ") : nil
      end

      def build
        {
          application_type: "web",
          response_types: ["id_token"],
          grant_types: ["implicit", "client_credentials"],
          initiate_login_uri: @initiate_login_url,
          redirect_uris: @redirect_uris,
          client_name: @tool_name,
          jwks_uri: @jwks_url,
          logo_uri: @logo_uri,
          policy_uri: @policy_uri,
          tos_uri: @tos_uri,
          token_endpoint_auth_method: "private_key_jwt",
          contacts: @contact_emails,
          scope: @scope,
          "https://purl.imsglobal.org/spec/lti-tool-configuration" => {
            domain: URI.parse(@root_url).host,
            description: @tool_description,
            target_link_uri: @root_url,
            claims: @claims,
            custom_parameters: @custom_params,
            messages: @messages
          }
        }
      end
    end
end
