# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "lti-bridge"
  spec.version = "0.1.0"
  spec.summary = "Helper gem for integrating LTI 1.3 into Rails tools"
  spec.description = "LTI Bridge 1.3 is a Ruby gem that simplifies integration of Learning Tools Interoperability (LTI) 1.3 into your Ruby on Rails tool. It handles login initiation, ID token validation, Deep Linking, Assignment and Grade Services, Names and Role Provisioning Services and Dynamic Registration. This gem makes it easier to connect your Rails application to LTI-complient LMS platforms."

  spec.authors = ["antonia173"]
  spec.email = ["blazevic.antonia01@gmail.com"]
  spec.homepage = "https://github.com/antonia173/lti-bridge"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.0.0"

  spec.files = Dir[
    "README.md",
    "LICENSE",
    "lib/**/*.rb"
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "openid_connect", "~> 1.2"
  spec.add_dependency "json-jwt", "~> 1.13"
  spec.add_dependency "httparty", "~> 0.18"
  spec.add_dependency "json", ">= 2.5"
end
