require "yaml"

module Designbook
  class DesignTokens
    def self.load(path: Designbook.configuration.design_tokens_path)
      new(path)
    end

    def initialize(path)
      @path = resolve_path(path)
      @data = load_yaml
    end

    def groups
      @data
    end

    def group(name)
      @data[name.to_s] || {}
    end

    def dig(*keys)
      @data.dig(*keys.map(&:to_s))
    end

    def present?
      @data.any?
    end

    def path
      @path
    end

    private

    def resolve_path(path)
      return nil if path.nil? || path.to_s.strip.empty?

      pathname = Pathname.new(path)
      pathname.absolute? ? pathname : Rails.root.join(pathname)
    end

    def load_yaml
      return {} unless @path&.exist?

      raw = YAML.safe_load(@path.read, permitted_classes: [], aliases: false) || {}
      raw.is_a?(Hash) ? stringify_keys(raw) : {}
    rescue Psych::SyntaxError => e
      Rails.logger.warn("[Designbook] Invalid design tokens YAML at #{@path}: #{e.message}")
      {}
    end

    def stringify_keys(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, child), memo|
          memo[key.to_s] = stringify_keys(child)
        end
      when Array
        value.map { |item| stringify_keys(item) }
      else
        value
      end
    end
  end
end
