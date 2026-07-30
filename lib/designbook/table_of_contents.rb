require "cgi"

module Designbook
  class TableOfContents
    Entry = Struct.new(:id, :text, :level, keyword_init: true)

    HEADING_PATTERN = %r{<(h[2-4])([^>]*)>(.*?)</\1>}mi

    def self.decorate(html)
      new(html).decorate
    end

    def initialize(html)
      @html = html.to_s
      @used_ids = {}
    end

    def decorate
      entries = []

      decorated = @html.gsub(HEADING_PATTERN) do
        tag = Regexp.last_match(1).downcase
        attrs = Regexp.last_match(2).to_s
        inner = Regexp.last_match(3).to_s
        level = tag.delete_prefix("h").to_i
        text = strip_tags(inner)
        id = ensure_id(attrs, text)
        attrs_without_id = attrs.gsub(/\s*\bid=(["'])[^"']*\1/, "")
        entries << Entry.new(id: id, text: text, level: level)
        %(<#{tag} id="#{escape_attr(id)}"#{attrs_without_id}><a class="db-heading-anchor" href="##{escape_attr(id)}" aria-label="Link to this section">#{inner}</a></#{tag}>)
      end

      [decorated, entries]
    end

    private

    def ensure_id(attrs, text)
      existing = attrs[/\bid=(["'])([^"']+)\1/, 2]
      base = existing.to_s.strip
      base = slugify(text) if base.empty?
      base = "section" if base.empty?

      count = @used_ids[base].to_i
      @used_ids[base] = count + 1
      count.zero? ? base : "#{base}-#{count}"
    end

    def slugify(text)
      text.to_s.downcase
          .gsub(/[^a-z0-9\s_-]/, "")
          .strip
          .gsub(/[\s_]+/, "-")
          .gsub(/-+/, "-")
          .delete_prefix("-")
          .delete_suffix("-")
    end

    def strip_tags(html)
      html.to_s.gsub(/<[^>]+>/, "").gsub(/\s+/, " ").strip
    end

    def escape_attr(value)
      CGI.escapeHTML(value.to_s)
    end
  end
end
