require "designbook/version"
require "designbook/engine"
require "designbook/page"
require "designbook/catalog"
require "designbook/design_tokens"
require "designbook/asset_path"
require "designbook/table_of_contents"
require "designbook/directive_registry"
require "designbook/directive_context"
require "designbook/component_embed"
require "designbook/token_renderer"
require "designbook/markdown_renderer"
require "pathname"

module Designbook
  class Error < StandardError; end
  class InvalidDocumentError < Error; end

  class Configuration
    attr_accessor :docs_path, :mount_path, :authenticate, :parent_controller,
                  :lookbook_preview_base_path, :lookbook_inspector_base_path,
                  :design_tokens_path, :assets_dirname

    def initialize
      @docs_path = "docs/designbook"
      @mount_path = "/designbook"
      @authenticate = nil
      @parent_controller = "ActionController::Base"
      @lookbook_preview_base_path = "/lookbook/embed"
      @lookbook_inspector_base_path = "/lookbook"
      @design_tokens_path = "config/design_tokens.yml"
      @assets_dirname = "assets"
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_catalog!
      @catalog = nil
    end

    def catalog
      if Rails.env.development?
        Catalog.build
      else
        @catalog ||= Catalog.build
      end
    end

    def design_tokens
      DesignTokens.load
    end

    def docs_root
      root = Pathname.new(configuration.docs_path)
      root.absolute? ? root : Rails.root.join(root)
    end

    def assets_root
      AssetPath.assets_root
    end

    def bundled_docs_root
      Pathname.new(File.expand_path("designbook/bundled_docs", __dir__))
    end

    def register_directive(name, &block)
      MarkdownRenderer.default_registry.register(name, &block)
    end
  end
end
