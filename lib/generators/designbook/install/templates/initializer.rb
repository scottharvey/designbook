Designbook.configure do |config|
  config.docs_path = Rails.root.join("docs/designbook")
  config.parent_controller = "ActionController::Base"
  config.design_tokens_path = Rails.root.join("config/design_tokens.yml")
  # Images live in docs/designbook/assets and are served at /designbook/assets/*
  # config.assets_dirname = "assets"

  # Optional: enforce host app auth
  # config.authenticate = -> { authenticate_admin! }

  # Optional Lookbook paths
  # config.lookbook_preview_base_path = "/lookbook/embed"
  # config.lookbook_inspector_base_path = "/lookbook"
end
