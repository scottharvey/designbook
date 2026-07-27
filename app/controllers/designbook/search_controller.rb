module Designbook
  class SearchController < ApplicationController
    helper_method :catalog, :query, :grouped_results

    def index
      @query = params[:q].to_s
      @grouped_results = catalog.search_grouped_by_section(@query)
    end

    private

    def catalog
      @catalog ||= Designbook.catalog
    end

    def query
      @query
    end

    def grouped_results
      @grouped_results || {}
    end
  end
end
