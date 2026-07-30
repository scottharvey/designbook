require "date"

module Designbook
  class Page
    attr_reader :source_path, :slug, :title, :order, :body_markdown, :section,
                :status, :version, :tags, :updated, :related_slugs, :description,
                :document_type, :purpose, :components_used

    def initialize(source_path:, slug:, title:, order:, body_markdown:, metadata: {})
      @source_path = source_path
      @slug = slug
      @title = title
      @order = order
      @body_markdown = body_markdown
      @section = derive_section(slug)
      apply_metadata(metadata)
    end

    def url_path
      return "/" if slug == "index"

      "/#{slug}"
    end

    def pattern?
      document_type == "pattern" || section == "patterns"
    end

    def metadata_present?
      !status.nil? || !version.nil? || !updated.nil? || tags.any?
    end

    def body_for_display
      body_markdown.to_s.sub(/\A(?:\s*\n)*#\s+#{Regexp.escape(title)}\s*(?:\n+|\z)/i, "")
    end

    private

    def apply_metadata(metadata)
      data = metadata.is_a?(Hash) ? metadata : {}

      @status = blank_to_nil(data["status"])
      @version = blank_to_nil(data["version"]&.to_s)
      @updated = parse_updated(data["updated"])
      @tags = Array(data["tags"]).map { |tag| tag.to_s.strip }.reject(&:empty?)
      @related_slugs = Array(data["related"]).map { |value| normalize_related(value) }.reject(&:empty?)
      @description = blank_to_nil(data["description"])
      @document_type = blank_to_nil(data["type"])&.downcase
      @purpose = blank_to_nil(data["purpose"])
      @components_used = Array(data["components"]).map { |value| value.to_s.strip }.reject(&:empty?)
    end

    def blank_to_nil(value)
      text = value.to_s.strip
      text.empty? ? nil : text
    end

    def parse_updated(value)
      return nil if value.nil?

      case value
      when Date
        value
      when Time
        value.to_date
      else
        Date.parse(value.to_s)
      end
    rescue ArgumentError, TypeError
      nil
    end

    def normalize_related(value)
      value.to_s.strip.sub(/\.md\z/, "").sub(%r{\A/+}, "").sub(%r{/index\z}, "")
    end

    def derive_section(value)
      return "root" if value == "index"

      value.split("/").first.to_s
    end
  end
end
