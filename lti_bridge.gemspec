# frozen_string_literal: true

require_relative "lib/lti_bridge/version"

Gem::Specification.new do |spec|
  spec.name = "lti-bridge"
  spec.version = "0.1.0"
  spec.authors = ["antonia173"]
  spec.email = ["blazevic.antonia01@gmail.com"]

  spec.summary = "Helper gem for integrating LTI 1.3 into Rails tools"
  spec.description = "LTI Bridge 1.3 is a Ruby gem that simplifies integration of Learning Tools Interoperability (LTI) 1.3 into your Ruby on Rails tool. It handles login initiation, ID token validation, Deep Linking, Assignment and Grade Services, Names and Role Provisioning Services and Dynamic Registration. This gem makes it easier to connect your Rails application to LTI-complient LMS platforms."

  spec.homepage = "https://github.com/antonia173/lti-bridge"

  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "openid_connect", "~> 1.2"
  spec.add_dependency "json-jwt", "~> 1.13"
  spec.add_dependency "httparty", "~> 0.18"
  spec.add_dependency "json", ">= 2.5"
end
