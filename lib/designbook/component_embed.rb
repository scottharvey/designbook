require "cgi"
require "yaml"

module Designbook
  class ComponentEmbed
    def self.render(argument:, body:, context:)
      new(argument: argument, body: body, context: context).render
    end

    def initialize(argument:, body:, context:)
      @argument = argument.to_s.strip
      @body = body.to_s
      @context = context
      @meta = parse_meta
    end

    def render
      raise ArgumentError, "Missing component preview id" if preview_id.empty?

      base = @context.configuration.lookbook_preview_base_path.to_s.sub(%r{/\z}, "")
      src = build_src(base)
      open_url = lookbook_open_url

      parts = []
      parts << %(<div class="db-component-embed" data-db-component="#{escape(preview_id)}">)
      parts << %(<div class="db-component-toolbar">)
      parts << %(<div class="db-component-meta">)
      parts << %(<p class="db-component-name">#{escape(display_name)}</p>)
      parts << %(<p class="db-component-description">#{escape(description)}</p>) if description
      parts << %(</div>)
      parts << %(<div class="db-component-actions">)
      parts << %(<a class="db-component-link" href="#{escape(source_url)}" target="_blank" rel="noopener noreferrer">Source</a>) if source_url
      parts << %(<a class="db-component-link" href="#{escape(open_url)}" target="_blank" rel="noopener noreferrer">Open in Lookbook</a>) if open_url
      parts << %(</div></div>)

      if params.any?
        parts << %(<div class="db-component-controls" data-db-preview-controls>)
        params.each do |key, value|
          parts << %(<label class="db-component-control"><span>#{escape(key)}</span>)
          parts << %(<input type="text" name="#{escape(key)}" value="#{escape(value)}" data-db-param="#{escape(key)}" />)
          parts << %(</label>)
        end
        parts << %(</div>)
      end

      parts << %(<div class="db-component-preview">)
      parts << %(<iframe class="db-preview-frame" src="#{escape(src)}" loading="lazy" title="Component preview: #{escape(preview_id)}" data-db-preview-base="#{escape(base)}" data-db-preview-id="#{escape(preview_id)}"></iframe>)
      parts << %(</div></div>)
      parts.join
    end

    private

    def parse_meta
      text = @body.strip
      return {} if text.empty?

      parsed = YAML.safe_load(text, permitted_classes: [], aliases: false)
      parsed.is_a?(Hash) ? parsed : { "description" => text }
    rescue Psych::SyntaxError
      { "description" => text }
    end

    def preview_id
      @argument
    end

    def display_name
      @meta["name"].presence || preview_id
    end

    def description
      value = @meta["description"].to_s.strip
      value.empty? ? nil : value
    end

    def source_url
      blank_to_nil(@meta["source"] || @meta["source_url"])
    end

    def lookbook_open_url
      explicit = blank_to_nil(@meta["lookbook"] || @meta["lookbook_url"])
      return explicit if explicit

      inspector = @context.configuration.lookbook_inspector_base_path.to_s.strip
      return nil if inspector.empty?

      "#{inspector.sub(%r{/\z}, "")}/#{preview_id}"
    end

    def params
      raw = @meta["params"] || @meta["parameters"] || {}
      return {} unless raw.is_a?(Hash)

      raw.transform_keys(&:to_s).transform_values(&:to_s)
    end

    def build_src(base)
      query = params.map { |key, value| "#{CGI.escape(key)}=#{CGI.escape(value)}" }.join("&")
      query.empty? ? "#{base}/#{preview_id}" : "#{base}/#{preview_id}?#{query}"
    end

    def blank_to_nil(value)
      text = value.to_s.strip
      text.empty? ? nil : text
    end

    def escape(value)
      CGI.escapeHTML(value.to_s)
    end
  end
end
