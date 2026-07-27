module Designbook
  module ApplicationHelper
    def designbook_page_path_for(page)
      return designbook.root_path if page.slug == "index"

      designbook.page_path(slug: page.slug)
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
  end
end
