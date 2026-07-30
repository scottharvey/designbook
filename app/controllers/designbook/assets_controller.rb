module Designbook
  class AssetsController < ApplicationController
    CONTENT_TYPES = {
      ".png" => "image/png",
      ".jpg" => "image/jpeg",
      ".jpeg" => "image/jpeg",
      ".gif" => "image/gif",
      ".webp" => "image/webp",
      ".svg" => "image/svg+xml",
      ".avif" => "image/avif",
      ".ico" => "image/x-icon",
      ".pdf" => "application/pdf"
    }.freeze

    def show
      path = Array(params[:path]).join("/")
      file = AssetPath.resolve_on_disk(path)
      raise ActionController::RoutingError, "Not Found" unless file

      send_file file,
                type: content_type_for(file),
                disposition: "inline",
                filename: file.basename.to_s
    end

    private

    def content_type_for(file)
      CONTENT_TYPES[file.extname.downcase] || "application/octet-stream"
    end
  end
end
