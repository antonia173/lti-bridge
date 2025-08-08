require "httparty"

module LtiBridge
  class DynamicRegistration
    def self.handle(request:, tool_config_builder:)
      params = request.params
      oidc_url = params["openid_configuration"]
      registration_token = params["registration_token"]

      raise "Missing required parameters" unless oidc_url

      platform_metadata = HTTParty.get(oidc_url).parsed_response
      registration_endpoint = platform_metadata["registration_endpoint"]

      raise "Missing registration_endpoint in platform metadata" unless registration_endpoint

      tool_config = tool_config_builder.build

      headers = {
        'Content-Type' => 'application/json'
      }
      headers['Authorization'] = "Bearer #{registration_token}" if registration_token

      response = HTTParty.post(
        registration_endpoint,
        headers: headers,
        body: tool_config.to_json
      )

      unless response.success?
        raise "Tool registration failed: #{response.code} - #{response.body}"
      end

      response = JSON.parse(response.body, symbolize_names: true)

      return { platform: {     
                issuer: platform_metadata["issuer"],
                auth_url: platform_metadata["authorization_endpoint"],
                token_url: platform_metadata["token_endpoint"],
                jwks_url: platform_metadata["jwks_uri"]
              },
              response: response 
            }
    end

    def self.html_page
      <<~HTML
      <!doctype html>
      <meta charset="utf-8">
      <title>LTI Registration</title>
      <script>
        (function() {
          try {
            (window.opener || window.parent).postMessage({ subject: 'org.imsglobal.lti.close' }, '*');
          } catch (e) {}
          setTimeout(function(){ try { window.close(); } catch(e){} }, 500);
        })();
      </script>
      <noscript>Registration completed. You can close this window.</noscript>
      HTML
    end

  end
end
