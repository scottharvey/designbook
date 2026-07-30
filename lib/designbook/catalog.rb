require "yaml"
require "set"
require "date"

module Designbook
  class Catalog
    SearchResult = Struct.new(:page, :score, :excerpt)

    attr_reader :pages

    def self.build
      new.build
    end

    def initialize
      @pages = []
      @outbound_links = Hash.new { |hash, key| hash[key] = Set.new }
    end

    def build
      load_docs_from(Designbook.bundled_docs_root)

      docs_root = Designbook.docs_root
      load_docs_from(docs_root) if docs_root.exist?

      @pages.sort_by! { |page| sort_key_for(page) }
      build_link_graph!
      self
    end

    def page_for_slug(slug)
      normalized = normalize_slug(slug)
      pages.find { |page| page.slug == normalized }
    end

    def ordered_pages
      pages
    end

    def reading_pages
      pages.reject { |page| page.section == "help" }
    end

    def previous_page_for(slug)
      page_at_offset(slug, -1)
    end

    def next_page_for(slug)
      page_at_offset(slug, 1)
    end

    def section_tree
      pages.group_by(&:section)
    end

    def search(query)
      normalized_query = query.to_s.strip.downcase
      return [] if normalized_query.empty?

      pages.filter_map do |page|
        score = search_score_for(page, normalized_query)
        next if score.zero?

        SearchResult.new(page, score, excerpt_for(page, normalized_query))
      end.sort_by { |result| [-result.score, result.page.slug] }
    end

    def search_grouped_by_section(query)
      search(query).group_by { |result| result.page.section }
    end

    def backlinks_for(slug)
      target = normalize_slug(slug)
      pages.select { |page| @outbound_links[page.slug].include?(target) }
    end

    def related_pages_for(page)
      linked = @outbound_links[page.slug].filter_map { |slug| page_for_slug(slug) }
      configured = page.related_slugs.filter_map { |slug| page_for_slug(slug) }
      (configured + linked).uniq(&:slug).reject { |related| related.slug == page.slug }
    end

    def search_index
      reading_pages.map do |page|
        {
          title: page.title,
          slug: page.slug,
          section: page.section,
          path: page_path_for(page),
          tags: page.tags,
          excerpt: searchable_lines_for(page).first.to_s[0, 140]
        }
      end
    end

    private

    def page_path_for(page)
      mount = Designbook.configuration.mount_path.to_s.sub(%r{/\z}, "")
      page.slug == "index" ? mount.presence || "/" : "#{mount}/#{page.slug}"
    end

    def load_docs_from(docs_root)
      return unless docs_root.exist?

      assets_prefix = File.join(docs_root.to_s, Designbook.configuration.assets_dirname.to_s)
      docs_root.glob("**/*.md").sort.each do |path|
        next if path.to_s.start_with?("#{assets_prefix}/") || path.to_s == assets_prefix

        add_page(path, docs_root, replace_existing: true)
      end
    end

    def add_page(path, docs_root, replace_existing: false)
      markdown = path.read
      metadata, content = extract_frontmatter(markdown, path)

      title = metadata["title"].to_s.strip
      if title.empty?
        raise_invalid_document!(path, "Missing required frontmatter key: title")
        return
      end

      relative = path.relative_path_from(docs_root).to_s
      slug = slug_for(relative)
      order = metadata["order"]
      order = Integer(order, exception: false)

      page = Page.new(
        source_path: path.to_s,
        slug: slug,
        title: title,
        order: order,
        body_markdown: content,
        metadata: metadata
      )

      existing_index = @pages.index { |existing| existing.slug == slug }
      if existing_index
        @pages[existing_index] = page if replace_existing
      else
        @pages << page
      end
    rescue Psych::SyntaxError => e
      raise_invalid_document!(path, "Invalid YAML frontmatter: #{e.message}")
    end

    def extract_frontmatter(markdown, path)
      lines = markdown.lines
      unless lines.first&.strip == "---"
        raise_invalid_document!(path, "Missing YAML frontmatter")
        return [{}, markdown]
      end

      closing_index = lines[1..]&.find_index { |line| line.strip == "---" }
      unless closing_index
        raise_invalid_document!(path, "Unclosed YAML frontmatter")
        return [{}, markdown]
      end

      closing_index += 1
      yaml = lines[1...closing_index].join
      content = lines[(closing_index + 1)..]&.join.to_s
      metadata = YAML.safe_load(yaml, permitted_classes: [Date, Time], aliases: false) || {}
      [metadata, content]
    end

    def slug_for(relative)
      cleaned = relative.sub(/\.md\z/, "")
      cleaned = cleaned.sub(%r{/index\z}, "")
      cleaned = "index" if cleaned.empty? || cleaned == "index"
      cleaned
    end

    def normalize_slug(slug)
      base = slug.to_s.sub(%r{\A/}, "").sub(%r{/\z}, "").sub(%r{/index\z}, "")
      return "index" if base.empty?

      base
    end

    def page_at_offset(slug, offset)
      page = page_for_slug(slug)
      return nil unless page
      return nil if page.section == "help"

      sequence = reading_pages
      index = sequence.index(page)
      return nil unless index

      target_index = index + offset
      return nil if target_index.negative? || target_index >= sequence.length

      sequence[target_index]
    end

    def sort_key_for(page)
      [page.slug == "index" ? 0 : 1, page.order || 9_999, page.section, page.slug]
    end

    def search_score_for(page, normalized_query)
      searchable_body = searchable_body_for(page)
      title_score = page.title.downcase.include?(normalized_query) ? 5 : 0
      slug_score = page.slug.downcase.include?(normalized_query) ? 3 : 0
      tag_score = page.tags.any? { |tag| tag.downcase.include?(normalized_query) } ? 2 : 0
      body_score = searchable_body.include?(normalized_query) ? 1 : 0
      title_score + slug_score + tag_score + body_score
    end

    def excerpt_for(page, normalized_query)
      lines = searchable_lines_for(page)
      match = lines.find { |line| line.downcase.include?(normalized_query) }
      return lines.first.to_s[0, 180] unless match

      match[0, 180]
    end

    def searchable_lines_for(page)
      stripped = strip_directive_syntax(page.body_markdown)
      stripped.lines.map { |line| cleanup_markdown_for_excerpt(line) }.reject(&:empty?)
    end

    def searchable_body_for(page)
      searchable_lines_for(page).join("\n").downcase
    end

    def strip_directive_syntax(markdown)
      markdown.gsub(/^\s*:::[\w-]+(?:\s+[^\n]+)?\s*$|^\s*:::\s*$/, "")
    end

    def cleanup_markdown_for_excerpt(line)
      cleaned = line.strip
      cleaned = cleaned.gsub(/\[([^\]]+)\]\(([^)]+)\)/, "\\1")
      cleaned = cleaned.gsub(/[`*_>#-]/, " ")
      cleaned.gsub(/\s+/, " ").strip
    end

    def build_link_graph!
      pages.each do |page|
        links = extract_markdown_links(page.body_markdown)
        links.each do |href|
          resolved = resolve_internal_link(page.slug, href)
          @outbound_links[page.slug] << resolved if resolved
        end
      end
    end

    def extract_markdown_links(markdown)
      markdown.scan(/\[[^\]]+\]\(([^)]+)\)/).flatten
    end

    def resolve_internal_link(current_slug, href)
      return nil if href.start_with?("http://", "https://", "#", "mailto:")

      mount_path = Designbook.configuration.mount_path.to_s
      if href.start_with?("#{mount_path}/")
        return normalize_slug(href.sub(%r{\A#{Regexp.escape(mount_path)}/?}, "").sub(/\.md\z/, ""))
      end

      return nil unless href.end_with?(".md")

      current_parts = current_slug.split("/")
      current_dir = current_slug == "index" ? [] : current_parts[0...-1]
      href_parts = href.sub(/\.md\z/, "").split("/")

      resolved = current_dir.dup
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

    def raise_invalid_document!(path, message)
      if Rails.env.development?
        raise InvalidDocumentError, "#{path}: #{message}"
      else
        Rails.logger.warn("[Designbook] Skipping invalid document #{path}: #{message}")
      end
    end
  end
end
