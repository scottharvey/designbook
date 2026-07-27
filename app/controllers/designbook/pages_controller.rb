module Designbook
  class PagesController < ApplicationController
    helper_method :catalog, :current_page, :previous_page, :next_page, :backlinks

    def show
      @current_page = catalog.page_for_slug(params[:slug])
      raise ActionController::RoutingError, "Not Found" unless @current_page

      @previous_page = catalog.previous_page_for(@current_page.slug)
      @next_page = catalog.next_page_for(@current_page.slug)
      @backlinks = catalog.backlinks_for(@current_page.slug)
      @rendered_html = MarkdownRenderer.new.render(@current_page.body_markdown, current_slug: @current_page.slug).html_safe
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
  end
end
