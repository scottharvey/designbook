module Designbook
  class DirectiveContext
    attr_reader :current_slug, :catalog, :configuration

    def initialize(current_slug:, catalog:, configuration:)
      @current_slug = current_slug
      @catalog = catalog
      @configuration = configuration
    end
  end
end
