module Designbook
  class ApplicationController < Designbook.configuration.parent_controller.constantize
    helper_method :current_page, :catalog
    before_action :authenticate_designbook!

    private

    def catalog
      @catalog ||= Designbook.catalog
    end

    def current_page
      nil
    end

    def authenticate_designbook!
      auth_callable = Designbook.configuration.authenticate
      return unless auth_callable

      instance_exec(&auth_callable)
    end
  end
end
