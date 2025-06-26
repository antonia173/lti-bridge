# LtiBridge

LtiBridge is a Ruby gem that provides support for the [LTI 1.3](https://www.1edtech.org/standards/lti) standard, making it easier to build LTI-compliant tools using Ruby on Rails. It abstracts away the protocol complexity and offers ready-to-use components for key LTI services, including:
- [Core Launch](https://www.imsglobal.org/spec/lti/v1p3/)
- [Deep Linking](https://www.imsglobal.org/spec/lti-dl/v2p0)
- [Assignment and Grade Services (AGS)](https://www.imsglobal.org/spec/lti-ags/v2p0/)
- [Names and Role Provisioning Services (NRPS)](https://www.imsglobal.org/spec/lti-nrps/v2p0)
- [Dynamic Registration](https://www.imsglobal.org/spec/lti-dr/v1p0)

## Installation

You can install this gem directly from GitHub by adding it to your Gemfile:
```
gem 'lti-bridge', git: 'https://github.com/antonia173/lti-bridge.git'
```
Then run: `bundle install`

To quickly scaffold the required structure for a basic LTI 1.3 integration, use the generator:
```
bin/rails generate lti_bridge:install
```

This will:
- Create required controller actions for login and launch
- Set up necessary routes
- Create a Platform model and migration to store LMS credentials

## Usage
After running `rails generate lti_bridge:install`, you can customize the controller to support different LTI 1.3 services.

### Login
`LoginInitiation` class handles LTI login initiation by generating the OIDC authorization URL.
```
# app/controllers/lti_controller.rb
def login
  platform = Platform.find_by(issuer: request.params["iss"], client_id: request.params["client_id"])
  redirect_to LtiBridge::LoginInitiation.handle(request, platform.auth_url), allow_other_host: true
end
```
config/routes.rb:
```
  post '/login',  to: 'lti#login'
```

### Launch
`LaunchRequest` class is used for validating id_token and extracting LTI claims.
```
  def launch
    launch = LtiBridge::LaunchRequest.new(request)

    # Example usage:
    # You can extract things like the user ID, name, roles, etc. from the launch
    # payload and use them in your application.
    data = launch.data
    @name = data.name || data.given_name || "User"

    render plain: "LTI Launch successful, welcome #{@name}!"
  end
```
config/router.rb:
```
  post '/launch', to: 'lti#launch'
```

#### Storing launch data
After a successful launch, the gem returns a `LaunchData` object that contains all the key claims extracted from the LTI `id_token`. Since services like AGS and NRPS require specific claims from this data, you’ll need to store it if you plan to use those services.
A common approach is using cache:
```
state = launch.data.state
Rails.cache.write("launch_#{state}", launch.data, expires_in: 10.minutes)
launch_data = Rails.cache.read("launch_#{params[:state]}")
```
You can also store it in a database, if needed. Choose a method that suits your environment. You can view the full structure of the LaunchData class [here](https://github.com/antonia173/lti-bridge/blob/main/lib/lti_bridge/launch/launch_data.rb)

### Signing JWTs
To sign JWTs (such as in deep linking response or access token requests), your tool must generate its own RSA private key. This private key should be securely stored in an environment variable: ENV["SSL_JWK_PRIVATE_KEY"]. 
The `Jwk` class loads this key and derives the corresponding public key in JWK format.

The public key must be exposed via a JWKS (JSON Web Key Set) endpoint so that LTI platforms can verify JWTs your tool signs:
```
# app/controllers/lti_controller.rb
def jwks
  jwk = LtiBridge::Jwk.build_from_env
  render json: { keys: [jwk] }
end
```
config/router.rb:
```
get '/.well-known/jwks.json', to: 'lti#jwks', as: 'jwks'
```

### Deep Linking

config/routes.rb
```
  post  '/deep_linking', to: 'lti#deep_linking'
  post '/deep_linking_response', to: 'lti#deep_linking_response
```
After receiving a [LtiDeepLinkingRequest](https://www.imsglobal.org/spec/lti-dl/v2p0#deep-linking-request-example), you should extract and store the launch data. You can then use that data to respond later:
```
  # app/controllers/lti_controller.rb
  def deep_linking
    launch = LtiBridge::LaunchRequest.new(request) # LtiDeepLinkingRequest
    launch_data = launch.data
    # store LaunchData object
  end
```
When the user finishes selecting or creating content in your tool, you respond back to the LMS:
```
  # app/controllers/lti_controller.rb
  def deep_linking_response
     content_item = LtiBridge::ContentItem.lti_resource_link(
      url: "https://my.tool/launch/123",
      title: "My Quiz",
      custom: { difficulty: "medium" },
    )

    launch_data = # retrieve LaunchData object

    form = LtiBridge::DeepLinkingResponse.new(
      launch_data: launch_data,
      content_items: [content_item]
    )
    render html: form.form_html.html_safe
  end
 ```
This will render and auto-submit an HTML form with a signed JWT ([LtiDeepLinkingResponse](https://www.imsglobal.org/spec/lti-dl/v2p0#deep-linking-response-example)) back to the LMS.

### Access token
LTI services (such as AGS and NRPS) use RESTful HTTP communication secured via OAuth 2.0 (Client Credentials Flow with JWT). The `AccessToken` class manages this flow by generating a signed JWT and posting it to the platform’s token endpoint. This token is required to authenticate API requests and ensures the tool has permission to access specific LTI services based on the provided `scope`.

### AGS
Assignment and Grade Services (AGS) is supported through two main classes:
- `LineItem`: Manages gradebook columns (line items)
  - `save`, `update`, `delete`: Create, update, or remove a line item
  - `self.get_lineitems`, `self.find_by`, `self.get`: Fetch line items
  - `self.find_or_create_by`: Reuse existing or create new line item
- `AGS`: Manages scores and results for a line item
  - `submit_score`: Submit or update a user's score for a specific line item
  - `get_results`: Retrieve all results for the given line item

All methods communicate with the [LTI AGS OpenAPI](https://www.imsglobal.org/spec/lti-ags/v2p0/openapi#/default).

Submitting score:
```
score_data = LtiBridge::Score.new(
    user_id: launch_data.user_id,
    activity_progress: "Completed",
    grading_progress: "FullyGraded",
    score_given: 0.53,
    score_maximum: 1.0
)

platform = Platform.find_by(issuer: launch_data.issuer, client_id: launch_data.audience)
ags_token = LtiBridge::AccessToken.fetch(issuer: platform.issuer, 
                                        client_id: platform.client_id, 
                                        token_url: platform.token_url,
                                        scope: launch_data.ags_scope)

lineitem = LtiBridge::LineItem.new(
    label: "Example title",
    score_maximum: 1.0,
    resource_link_id: launch_data.resource_link["id"],
)
lineitem.save(access_token: ags_token, lineitems_url: launch_data.ags_lineitems)

ags = LtiBridge::AGS.new(access_token: ags_token)
ags.submit_score(score: score_data, lineitem: lineitem)
```
Fetching results:
```
platform = Platform.find_by(issuer: launch_data.issuer, client_id: launch_data.audience)
token = LtiBridge::AccessToken.fetch(issuer: platform.issuer, 
                                        client_id: platform.client_id, 
                                        token_url: platform.token_url,
                                        scope: launch_data.ags_scope)

lineitem = LtiBridge::LineItem.find_by(
      access_token: token,
      lineitems_url: launch_data.ags_lineitems,
      resource_link_id: launch_data.resource_link["id"])

ags = LtiBridge::AGS.new(access_token: token)
ags.get_results(lineitem_id: lineitem.id)
```

### NRPS
Names and Role Provisioning Services lets your tool fetch the list of users and their roles within the current course. You can optionally query members by role (e.g., Learner, Instructor). The response includes user details (e.g. user ID, name, username, email and role), allowing your tool to understand who is in the course and their permissions.
```
platform = Platform.find_by(issuer: launch_data.issuer, client_id: launch_data.audience)
token = LtiBridge::AccessToken.fetch(issuer: platform.issuer, 
                                        client_id: platform.client_id, 
                                        token_url: platform.token_url,
                                        scope: launch_data.nrps_scope)
nrps = LtiBridge::NRPS.new(access_token: token, memberships_url: launch_data.nrps_context_memberships_url)
members = nrps.members(query: { role: "Learner" })
```
### Dynamic Registration
Dynamic Registration enables a tool to automatically register itself with an LMS platform. When the platform sends a registration request, the `DynamicRegistration` class retrieves the platform’s metadata and sends your tool’s configuration (built using the `ToolConfiguration` class) to the provided registration endpoint. The `handle` method manages this process and returns the platform’s details and the tool’s registration information, including the client_id if the registration works.

```
  def register
    result = LtiBridge::DynamicRegistration.handle(
      request: request,
      tool_config_builder: tool_config_builder
    )
    
    platform = Platform.create!(
      issuer: result[:platform][:issuer],
      client_id: result[:response][:client_id],
      auth_url: result[:platform][:auth_url],
      token_url: result[:platform][:token_url],
      jwks_url: result[:platform][:jwks_url]
    )

    render plain: "Dynamic registration successful!"
  end

  def tool_config_builder
    LtiBridge::ToolConfiguration.new(
      initiate_login_url: login_url,
      jwks_url: jwks_url,
      redirect_uris: [launch_url],
      tool_name: "My Tool",
      root_url: root_url,
      contact_emails: ["admin@yourdomain.com"],
      tool_description: "A simple LTI tool",
      messages: [
        {
          type: "LtiDeepLinkingRequest",
          target_link_uri: deep_linking_url
        }
      ], 
      nrps: true,
      ags_grade_sync_column_mngmt: true,
      share_user_name: true,
      share_email: true
    )
  end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/antonia173/lti-bridge.