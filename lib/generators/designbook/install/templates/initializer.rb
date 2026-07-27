Designbook.configure do |config|
  config.docs_path = Rails.root.join("docs/designbook")
  config.parent_controller = "ActionController::Base"

  # Optional: enforce host app auth
  # config.authenticate = -> { authenticate_admin! }
end
