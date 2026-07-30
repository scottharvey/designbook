module Designbook
  class PagesController < ApplicationController
    helper_method :catalog, :current_page, :previous_page, :next_page, :backlinks, :related_pages, :toc_entries

    rescue_from ActionController::RoutingError, with: :render_not_found

    def show
      @current_page = catalog.page_for_slug(params[:slug])
      return render_not_found unless @current_page

      @previous_page = catalog.previous_page_for(@current_page.slug)
      @next_page = catalog.next_page_for(@current_page.slug)
      @backlinks = catalog.backlinks_for(@current_page.slug)
      @related_pages = catalog.related_pages_for(@current_page)
      result = MarkdownRenderer.new.render(@current_page.body_for_display, current_slug: @current_page.slug)
      @rendered_html = result.html.html_safe
      @toc_entries = result.toc
    end

    private

    def catalog
      @catalog ||= Designbook.catalog
    end

    def current_page
      @current_page
    end

    def previous_page
      @previous_page
    end

    def next_page
      @next_page
    end

    def backlinks
      @backlinks || []
    end

    def related_pages
      @related_pages || []
    end

    def toc_entries
      @toc_entries || []
    end

    def render_not_found
      @current_page = nil
      @toc_entries = []
      render "designbook/pages/not_found", status: :not_found
    end
  end
end
