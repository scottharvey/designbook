module Designbook
  class Page
    attr_reader :source_path, :slug, :title, :order, :body_markdown, :section

    def initialize(source_path:, slug:, title:, order:, body_markdown:)
      @source_path = source_path
      @slug = slug
      @title = title
      @order = order
      @body_markdown = body_markdown
      @section = derive_section(slug)
    end

    def url_path
      return "/" if slug == "index"

      "/#{slug}"
    end

    private

    def derive_section(value)
      return "root" if value == "index"

      value.split("/").first.to_s
    end
  end
end
