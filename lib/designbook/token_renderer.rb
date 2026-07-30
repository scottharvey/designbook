require "cgi"

module Designbook
  class TokenRenderer
    def self.render(group:, context:)
      new(group: group, context: context).render
    end

    def initialize(group:, context:)
      @group = group.to_s.strip
      @tokens = DesignTokens.load
      @context = context
    end

    def render
      unless @tokens.present?
        return %(<aside class="db-callout db-callout-warning"><p class="db-callout-title">Tokens</p><p>No design tokens found. Add <code>config/design_tokens.yml</code> or set <code>config.design_tokens_path</code>.</p></aside>)
      end

      groups = if @group.empty?
        @tokens.groups
      else
        { @group => @tokens.group(@group) }
      end

      if groups.values.all? { |value| value.nil? || value.empty? }
        return %(<aside class="db-callout db-callout-warning"><p class="db-callout-title">Tokens</p><p>No tokens found for group <code>#{escape(@group)}</code>.</p></aside>)
      end

      parts = [%(<div class="db-tokens">)]
      groups.each do |name, values|
        next if values.nil? || values.empty?

        parts << %(<section class="db-token-group" id="tokens-#{slugify(name)}">)
        parts << %(<h3 class="db-token-group-title">#{escape(titleize(name))}</h3>)
        parts << render_group(name, values)
        parts << %(</section>)
      end
      parts << %(</div>)
      parts.join
    end

    private

    def render_group(group_name, values)
      case values
      when Hash
        if color_group?(group_name, values)
          render_color_swatches(values)
        else
          render_table(values)
        end
      else
        %(<p class="db-token-value"><code>#{escape(values)}</code></p>)
      end
    end

    def color_group?(name, values)
      name.match?(/colou?r/i) && values.values.all? { |value| value.is_a?(String) }
    end

    def render_color_swatches(values)
      items = values.map do |token, value|
        %(<li class="db-token-swatch"><span class="db-token-swatch-chip" style="background: #{escape(value)}"></span><div><code>#{escape(token)}</code><span class="db-token-swatch-value">#{escape(value)}</span></div></li>)
      end
      %(<ul class="db-token-swatches">#{items.join}</ul>)
    end

    def render_table(values, prefix: nil)
      rows = flatten_tokens(values, prefix: prefix).map do |token, value|
        %(<tr><th scope="row"><code>#{escape(token)}</code></th><td><code>#{escape(value)}</code></td></tr>)
      end
      %(<table class="db-token-table"><thead><tr><th>Token</th><th>Value</th></tr></thead><tbody>#{rows.join}</tbody></table>)
    end

    def flatten_tokens(values, prefix: nil)
      values.flat_map do |key, value|
        path = [prefix, key].compact.join(".")
        case value
        when Hash
          flatten_tokens(value, prefix: path)
        else
          [[path, value]]
        end
      end
    end

    def titleize(value)
      value.to_s.tr("_-", " ").split.map(&:capitalize).join(" ")
    end

    def slugify(value)
      value.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
    end

    def escape(value)
      CGI.escapeHTML(value.to_s)
    end
  end
end
