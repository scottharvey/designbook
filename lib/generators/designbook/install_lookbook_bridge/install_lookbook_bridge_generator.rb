require "rails/generators"

module Designbook
  module Generators
    class InstallLookbookBridgeGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def ensure_lookbook_is_present
        return if defined?(Lookbook)

        raise Thor::Error, "Lookbook must be installed before running this generator."
      end

      def create_initializer
        if File.exist?("config/initializers/designbook_lookbook_bridge.rb")
          say_status :skip, "config/initializers/designbook_lookbook_bridge.rb already exists", :yellow
          return
        end

        template "lookbook_bridge.rb", "config/initializers/designbook_lookbook_bridge.rb"
      end

      def copy_example_page
        if File.exist?("docs/designbook/components/button.md")
          say_status :skip, "docs/designbook/components/button.md already exists", :yellow
          return
        end

        template "components_button.md", "docs/designbook/components/button.md"
      end

      def show_post_install_notes
        say "\nLookbook bridge installed."
        say "Add `:::component button/default` blocks in Designbook markdown pages."
      end
    end
  end
end
