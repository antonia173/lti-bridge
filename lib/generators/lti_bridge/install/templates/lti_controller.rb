require 'lti_bridge'

class LtiController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :allow_iframe

  # Handles LTI login initiation by generating the OIDC authorization URL and redirecting to target_link_uri
  def login
    platform = Platform.find_by(issuer: request.params["iss"], client_id: request.params["client_id"])
	  login_url = LtiBridge::LoginInitiation.handle(request, platform.auth_url)
    redirect_to login_url, allow_other_host: true
  end

  # Customize this method to build your own tool launch behavior.
  def example_launch
    return render(plain: "This page requires LTI 1.3 launch.", status: :unauthorized) unless params[:id_token].present?

    launch = LtiBridge::LaunchRequest.new(request)
    @data = launch.data
    @name = @data.name || @data.given_name || "User"
  end

  # Exposes your tool’s public key so platforms can verify JWTs signed by your tool.
  def jwks
    jwk = LtiBridge::Jwk.build_from_env
    render json: { keys: [jwk] }
  end

  private

  # Allows this controller's views to be embedded in iframes in an LMS
  def allow_iframe
    response.headers.except!('X-Frame-Options')
  end
end
