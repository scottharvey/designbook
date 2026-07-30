require "test_helper"
require "fileutils"
require "base64"

class DesignbookAssetsTest < ActionDispatch::IntegrationTest
  setup do
    @assets_dir = Designbook.assets_root
    FileUtils.mkdir_p(@assets_dir)
    @image_path = @assets_dir.join("sample.png")
    # Minimal valid 1x1 PNG
    @image_path.binwrite(Base64.decode64(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
    ))
  end

  teardown do
    FileUtils.rm_f(@image_path)
  end

  test "serves assets from docs assets folder" do
    get "/designbook/assets/sample.png"

    assert_response :success
    assert_equal "image/png", response.media_type
  end

  test "rejects path traversal outside assets" do
    get "/designbook/assets/../index.md"

    assert_response :not_found
  end

  test "rewrites markdown image paths to designbook assets" do
    renderer = Designbook::MarkdownRenderer.new
    result = renderer.render("![Sample](assets/sample.png)", current_slug: "index")

    assert_includes result.html, 'src="/designbook/assets/sample.png"'
  end

  test "rewrites screenshot directive paths to designbook assets" do
    renderer = Designbook::MarkdownRenderer.new
    result = renderer.render(":::screenshot assets/sample.png\n:::", current_slug: "index")

    assert_includes result.html, 'src="/designbook/assets/sample.png"'
  end
end
