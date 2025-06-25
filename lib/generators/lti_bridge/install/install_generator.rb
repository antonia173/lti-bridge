require 'rails/generators'
require 'rails/generators/migration'

module LtiBridge
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('templates', __dir__)

    def create_migration_file
      migration_template "create_platforms.rb", "db/migrate/create_platforms.rb"
    end

    def create_model_file
      template "platform.rb", "app/models/platform.rb"
    end

    def create_controller_file
      template "lti_controller.rb", "app/controllers/lti_controller.rb"
    end

    def create_view_file
      template "example_launch.html.erb", "app/views/lti/example_launch.html.erb"
    end

    def add_routes
      route <<~ROUTES
        post  '/lti/login',  to: 'lti#login'
        post '/lti/launch', to: 'lti#launch'
        get '/.well-known/jwks.json', to: 'lti#jwks', as: 'jwks'
      ROUTES
    end

    def self.next_migration_number(dirname)
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    end

  end
end
