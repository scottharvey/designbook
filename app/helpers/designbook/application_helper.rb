module Designbook
  module ApplicationHelper
    def designbook_page_path_for(page)
      return designbook.root_path if page.slug == "index"

      designbook.page_path(slug: page.slug)
    end

    def designbook_page(slug)
      catalog.page_for_slug(normalize_designbook_slug(slug))
    end

    def designbook_url(slug, only_path: true)
      page = designbook_page(slug)
      path = if page
        designbook_page_path_for(page)
      else
        designbook_fallback_path(slug)
      end

      only_path ? path : "#{request.base_url}#{path}"
    end

    def designbook_link(slug, text = nil, **html_options)
      page = designbook_page(slug)
      label = text.presence || page&.title || slug.to_s
      link_to label, designbook_url(slug), html_options
    end

    def designbook_component_link(preview_id, text = nil, **html_options)
      label = text.presence || preview_id.to_s
      base = Designbook.configuration.lookbook_inspector_base_path.to_s.sub(%r{/\z}, "")
      link_to label, "#{base}/#{preview_id}", html_options.merge(target: "_blank", rel: "noopener noreferrer")
    end

    def designbook_token_link(token_path, text = nil, **html_options)
      label = text.presence || token_path.to_s
      group = token_path.to_s.split(".").first
      anchor = "tokens-#{group.to_s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')}"
      tokens_page = catalog.page_for_slug("foundations/tokens") || catalog.page_for_slug("tokens")
      href = tokens_page ? "#{designbook_page_path_for(tokens_page)}##{anchor}" : "##{anchor}"
      link_to label, href, html_options
    end

    def section_title(section_key)
      return "General" if section_key == "root"

      section_key.to_s.tr("_-", " ").split.map(&:capitalize).join(" ")
    end

    def breadcrumb_pages_for(page)
      return [] if page.slug == "index"

      segments = page.slug.split("/")
      crumbs = []
      segments[0...-1].each_with_index do |_segment, idx|
        crumb_slug = segments[0..idx].join("/")
        landing_slug = "#{crumb_slug}/index"
        target = catalog.page_for_slug(landing_slug) || catalog.page_for_slug(crumb_slug)
        crumbs << target if target
      end
      crumbs
    end

    def active_search?(query)
      query.to_s.strip.length.positive?
    end

    def format_updated(date)
      return nil unless date

      date.strftime("%b %-d, %Y")
    end

    def highlight_search_excerpt(excerpt, query)
      text = ERB::Util.html_escape(excerpt.to_s)
      needle = query.to_s.strip
      return text if needle.empty?

      pattern = Regexp.new(Regexp.escape(needle), Regexp::IGNORECASE)
      text.gsub(pattern) { |match| "<mark>#{match}</mark>" }.html_safe
    end

    def search_index_json
      catalog.search_index.to_json
    end

    def current_section_key
      current_page&.section
    end

    def nav_section_expanded?(section)
      current_section_key == section
    end

    private

    def normalize_designbook_slug(slug)
      value = slug.to_s.strip.sub(%r{\A/}, "").sub(%r{\.md\z}, "").sub(%r{/index\z}, "")
      value.empty? ? "index" : value
    end

    def designbook_fallback_path(slug)
      mount = Designbook.configuration.mount_path.to_s.sub(%r{/\z}, "")
      normalized = normalize_designbook_slug(slug)
      normalized == "index" ? mount : "#{mount}/#{normalized}"
    end
  end
end
