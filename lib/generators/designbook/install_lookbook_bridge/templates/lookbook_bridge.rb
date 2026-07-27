Designbook.configure do |config|
  # Use Lookbook's embed path (component only), not /inspect (full Lookbook UI).
  # Example: :::component ui/badge
  #          /lookbook/embed/ui/badge
  config.lookbook_preview_base_path = "/lookbook/embed"
end
