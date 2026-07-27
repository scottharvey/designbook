module Designbook
  class Engine < ::Rails::Engine
    isolate_namespace Designbook

    config.designbook = ActiveSupport::OrderedOptions.new

    initializer "designbook.reset_catalog_on_prepare" do
      ActiveSupport::Reloader.to_prepare do
        Designbook.reset_catalog! if Rails.env.development?
      end
    end
  end
end
