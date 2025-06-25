# LtiBridge

TODO: Describe gem here

## Installation

You can install this gem directly from Git by adding this to your Gemfile:
```
gem 'lti-bridge', git: 'https://github.com/antonia173/lti-bridge.git'
```
Then run: `bundle install`

This gem provides Rails generators to help you quickly set up the necessary files for simple LTI launch:
```
bin/rails generate lti_bridge:install
```

This will:
- Create required controller actions for login and launch
- Create view for simple launch
- Generate routes
- Create a Platform model and migration to store LMS credentials.

## Usage

TODO: Write usage instructions here

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/antonia173/lti-bridge.