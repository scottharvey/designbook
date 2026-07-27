require "cgi"
require "commonmarker"
require "rouge"
require "securerandom"
require "rails-html-sanitizer"

module Designbook
  class MarkdownRenderer
    DIRECTIVE_TOKEN_PREFIX = "DBDIRTOKEN".freeze

    SANITIZER = Rails::HTML5::SafeListSanitizer.new
    SANITIZER_TAGS = %w[
      a aside blockquote br code div em figcaption figure iframe img li ol p pre
      span strong ul
    ].freeze
    SANITIZER_ATTRIBUTES = %w[
      alt aria-label class href loading src title target rel
    ].freeze

    def initialize(registry: self.class.default_registry, catalog: Designbook.catalog)
      @registry = registry
      @catalog = catalog
    end

    def render(markdown, current_slug: "index")
      @current_slug = current_slug
      @directive_context = DirectiveContext.new(
        current_slug: current_slug,
        catalog: @catalog,
        configuration: Designbook.configuration
      )

      directive_store = {}
      with_placeholders = render_directives(markdown, directive_store)
      html = to_html(with_placeholders)
      html = inject_directives(html, directive_store)
      highlighted = highlight_code_blocks(html)
      rewrite_internal_links(highlighted)
    end

    def self.default_registry
      @default_registry ||= DirectiveRegistry.new.tap do |registry|
        registry.register("note") do |_argument, body, _context|
          %(<aside class="db-callout db-callout-note"><p class="db-callout-title">Note</p>#{MarkdownRenderer.to_html(body.to_s)}</aside>)
        end

        registry.register("warning") do |_argument, body, _context|
          %(<aside class="db-callout db-callout-warning"><p class="db-callout-title">Warning</p>#{MarkdownRenderer.to_html(body.to_s)}</aside>)
        end

        registry.register("tip") do |_argument, body, _context|
          %(<aside class="db-callout db-callout-tip"><p class="db-callout-title">Tip</p>#{MarkdownRenderer.to_html(body.to_s)}</aside>)
        end

        registry.register("principle") do |_argument, body, _context|
          %(<blockquote class="db-principle"><p class="db-principle-label">Principle</p>#{MarkdownRenderer.to_html(body.to_s)}</blockquote>)
        end

        registry.register("screenshot") do |argument, _body, _context|
          path = argument.to_s.strip
          raise ArgumentError, "Missing screenshot path" if path.empty?

          %(<figure class="db-screenshot"><img src="#{CGI.escapeHTML(path)}" alt="Screenshot: #{CGI.escapeHTML(path)}" loading="lazy" /><figcaption>#{CGI.escapeHTML(path)}</figcaption></figure>)
        end

        registry.register("component") do |argument, _body, context|
          preview_id = argument.to_s.strip
          raise ArgumentError, "Missing component preview id" if preview_id.empty?

          base = context.configuration.lookbook_preview_base_path.to_s.sub(%r{/\z}, "")
          src = "#{base}/#{preview_id}"
          %(<div class="db-component-preview"><iframe class="db-preview-frame" src="#{CGI.escapeHTML(src)}" loading="lazy" title="Component preview: #{CGI.escapeHTML(preview_id)}"></iframe></div>)
        end
      end
    end

    def self.to_html(markdown)
      options = {
        parse: Commonmarker::Config::OPTIONS[:parse].dup,
        render: Commonmarker::Config::OPTIONS[:render].dup.merge(unsafe: false),
        extension: Commonmarker::Config::OPTIONS[:extension].dup
      }

      Commonmarker.to_html(utf8(markdown), options: options, plugins: { syntax_highlighter: nil })
    end

    def self.utf8(text)
      text.to_s.encode("UTF-8")
    end

    def to_html(markdown)
      self.class.to_html(markdown)
    end

    private

    def render_directives(markdown, directive_store)
      lines = markdown.to_s.lines
      out = +""

      i = 0
      while i < lines.length
        line = lines[i]

        open = line.match(/^\s*:::(\w+)(?:\s+([^\n]+))?\s*$/)
        unless open
          out << line
          i += 1
          next
        end

        name = open[1]
        argument = (open[2] || "").strip
        i += 1

        body_lines = []
        while i < lines.length && !(lines[i] =~ /^\s*:::\s*$/)
          body_lines << lines[i]
          i += 1
        end

        if i >= lines.length
          out << directive_error_card("Unclosed directive: #{name}")
          break
        end

        body = body_lines.join
        rendered = begin
          @registry.render(name, argument, body, context: @directive_context)
        rescue StandardError => e
          directive_error_card("Failed to render directive #{name}: #{e.message}")
        end

        token = next_directive_token
        directive_store[token] = sanitize_directive_html(rendered || directive_error_card("Unknown directive: #{name}"))

        out << "\n#{token}\n"

        # Skip closing line
        i += 1
      end

      out
    end

    def inject_directives(html, directive_store)
      output = html.dup
      directive_store.each do |token, rendered_html|
        output.gsub!("<p>#{token}</p>", rendered_html)
        output.gsub!(token, rendered_html)
      end
      output
    end

    def sanitize_directive_html(html)
      SANITIZER.sanitize(
        html.to_s,
        tags: SANITIZER_TAGS,
        attributes: SANITIZER_ATTRIBUTES
      )
    end

    def next_directive_token
      "#{DIRECTIVE_TOKEN_PREFIX}:#{SecureRandom.hex(8)}"
    end

    def rewrite_internal_links(html)
      html.gsub(/href="([^"]+)"/) do
        href = Regexp.last_match(1)
        %{href="#{CGI.escapeHTML(rewrite_href(href))}"}
      end
    end

    def rewrite_href(href)
      return href if href.start_with?("http://", "https://", "#", "mailto:")
      mount_path = Designbook.configuration.mount_path.to_s
      if href.start_with?("#{mount_path}/")
        slug = normalize_slug(href.sub(%r{\A#{Regexp.escape(mount_path)}/?}, "").sub(%r{\.md\z}, ""))
        return slug == "index" ? mount_path : "#{mount_path}/#{slug}"
      end

      return href unless href.end_with?(".md")

      slug = resolve_relative_slug(@current_slug, href)
      slug == "index" ? mount_path : "#{mount_path}/#{slug}"
    end

    def resolve_relative_slug(current_slug, href)
      current_parts = current_slug.to_s == "index" ? [] : current_slug.to_s.split("/")[0...-1]
      href_parts = href.sub(%r{\.md\z}, "").split("/")

      resolved = current_parts.dup
      href_parts.each do |part|
        next if part == "."

        if part == ".."
          resolved.pop
        else
          resolved << part
        end
      end

      normalize_slug(resolved.join("/"))
    end

    def normalize_slug(value)
      normalized = value.to_s.sub(%r{\A/}, "").sub(%r{/\z}, "")
      normalized = normalized.sub(%r{/index\z}, "")
      normalized.empty? ? "index" : normalized
    end

    def highlight_code_blocks(html)
      # Commonmarker 2.x emits either:
      #   <pre><code class="language-ruby">...</code></pre>
      # or with github_pre_lang:
      #   <pre lang="ruby"><code>...</code></pre>
      html.gsub(%r{<pre(?:\s+lang="([^"]+)")?><code(?:\s+class="language-([^"]+)")?>(.*?)</code></pre>}m) do
        language_from_lang = Regexp.last_match(1)
        language_from_class = Regexp.last_match(2)
        language =
          if language_from_lang && !language_from_lang.to_s.strip.empty?
            language_from_lang
          elsif language_from_class && !language_from_class.to_s.strip.empty?
            language_from_class
          else
            nil
          end
        code = CGI.unescapeHTML(Regexp.last_match(3).to_s)
        lexer = if language
          Rouge::Lexer.find_fancy(language, code) || Rouge::Lexers::PlainText.new
        else
          Rouge::Lexers::PlainText.new
        end
        formatter = Rouge::Formatters::HTML.new
        %(<pre><code class="highlight">#{formatter.format(lexer.lex(code))}</code></pre>)
      end
    end

    def directive_error_card(message)
      %(<aside class="db-callout db-callout-error"><p class="db-callout-title">Directive error</p><p>#{CGI.escapeHTML(message)}</p></aside>)
    end
  end
end
