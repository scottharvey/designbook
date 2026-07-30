module Designbook
  class AssetPath
    IMAGE_EXTENSIONS = %w[.png .jpg .jpeg .gif .webp .svg .avif .ico .pdf].freeze

    def self.assets_root
      Designbook.docs_root.join(Designbook.configuration.assets_dirname)
    end

    def self.public_url_for(relative_path)
      mount = Designbook.configuration.mount_path.to_s.sub(%r{/\z}, "")
      dirname = Designbook.configuration.assets_dirname.to_s.sub(%r{\A/+}, "").sub(%r{/+\z}, "")
      cleaned = relative_path.to_s.sub(%r{\A/+}, "")
      "#{mount}/#{dirname}/#{cleaned}"
    end

    def self.rewrite(src, current_slug: "index")
      value = src.to_s.strip
      return value if value.empty?
      return value if value.start_with?("http://", "https://", "data:", "#")

      mount = Designbook.configuration.mount_path.to_s.sub(%r{/\z}, "")
      dirname = Designbook.configuration.assets_dirname.to_s

      if value.start_with?("#{mount}/#{dirname}/")
        return value
      end

      relative = strip_docs_asset_prefix(value, mount: mount, dirname: dirname)
      relative ||= resolve_relative_asset(value, current_slug: current_slug)
      return value unless relative

      public_url_for(relative)
    end

    def self.resolve_on_disk(path_param)
      root = assets_root.expand_path
      return nil unless root.exist?

      candidate = root.join(path_param.to_s).expand_path
      return nil unless under_root?(candidate, root)
      return nil unless candidate.file?

      candidate
    end

    def self.asset_reference?(path)
      value = path.to_s.strip
      return false if value.empty?
      return false if value.start_with?("http://", "https://", "data:", "#")

      mount = Designbook.configuration.mount_path.to_s.sub(%r{/\z}, "")
      dirname = Designbook.configuration.assets_dirname.to_s
      return true if value.start_with?("#{dirname}/", "./#{dirname}/", "/#{dirname}/", "#{mount}/#{dirname}/")

      IMAGE_EXTENSIONS.include?(File.extname(value).downcase)
    end

    def self.strip_docs_asset_prefix(value, mount:, dirname:)
      patterns = [
        %r{\A#{Regexp.escape(mount)}/#{Regexp.escape(dirname)}/},
        %r{\A/#{Regexp.escape(dirname)}/},
        %r{\A\./#{Regexp.escape(dirname)}/},
        %r{\A#{Regexp.escape(dirname)}/}
      ]

      patterns.each do |pattern|
        return value.sub(pattern, "") if value.match?(pattern)
      end

      nil
    end
    private_class_method :strip_docs_asset_prefix

    def self.resolve_relative_asset(value, current_slug:)
      return nil unless IMAGE_EXTENSIONS.include?(File.extname(value).downcase)

      current_parts = current_slug.to_s == "index" ? [] : current_slug.to_s.split("/")[0...-1]
      parts = value.split("/")
      resolved = current_parts.dup

      parts.each do |part|
        next if part.empty? || part == "."

        if part == ".."
          resolved.pop
        else
          resolved << part
        end
      end

      relative = resolved.join("/")
      dirname = Designbook.configuration.assets_dirname.to_s
      return nil unless relative.start_with?("#{dirname}/")

      relative.delete_prefix("#{dirname}/")
    end
    private_class_method :resolve_relative_asset

    def self.under_root?(candidate, root)
      candidate.to_s == root.to_s || candidate.to_s.start_with?("#{root}/")
    end
    private_class_method :under_root?
  end
end
