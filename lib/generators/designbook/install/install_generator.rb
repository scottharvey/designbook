require "rails/generators"

module Designbook
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_initializer
        if File.exist?("config/initializers/designbook.rb")
          say_status :skip, "config/initializers/designbook.rb already exists", :yellow
          return
        end

        template "initializer.rb", "config/initializers/designbook.rb"
      end

      def copy_docs
        if Dir.exist?("docs/designbook")
          say_status :skip, "docs/designbook already exists", :yellow
          return
        end

        directory "docs/designbook", "docs/designbook"
      end

      def mount_engine
        routes_file = "config/routes.rb"
        mount_line = %(mount Designbook::Engine => "/designbook")

        if File.exist?(routes_file) && File.read(routes_file).include?(mount_line)
          say_status :skip, "Designbook route already mounted", :yellow
          return
        end

        route mount_line
      end

      def show_post_install_notes
        say "\nDesignbook installed."
        say "Visit /designbook after restarting your Rails server."
        say "Run `bin/rails g designbook:install_lookbook_bridge` to wire Lookbook previews."
      end
    end
  end
end
