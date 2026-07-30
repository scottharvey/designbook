require "rails/generators"

module Designbook
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_initializer
        if File.exist?("config/initializers/designbook.rb")
          say_status :skip, "config/initializers/designbook.rb already exists", :yellow
        else
          template "initializer.rb", "config/initializers/designbook.rb"
        end
      end

      def copy_design_tokens
        if File.exist?("config/design_tokens.yml")
          say_status :skip, "config/design_tokens.yml already exists", :yellow
        else
          template "design_tokens.yml", "config/design_tokens.yml"
        end
      end

      def copy_docs
        if Dir.exist?("docs/designbook")
          say_status :skip, "docs/designbook already exists", :yellow
        else
          directory "docs/designbook", "docs/designbook"
        end

        assets_dir = "docs/designbook/assets"
        assets_readme = File.join(assets_dir, "README.md")
        if File.exist?(assets_readme)
          say_status :skip, "#{assets_readme} already exists", :yellow
        else
          empty_directory assets_dir
          template "docs/designbook/assets/README.md", assets_readme
        end
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
