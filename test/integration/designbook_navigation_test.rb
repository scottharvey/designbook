require "test_helper"

class DesignbookNavigationTest < ActionDispatch::IntegrationTest
  test "renders root page" do
    get "/designbook"

    assert_response :success
    assert_includes response.body, "Designbook"
  end

  test "renders search results" do
    get "/designbook/search", params: { q: "typography" }

    assert_response :success
    assert_includes response.body, "Search"
    assert_includes response.body, "Typography"
  end

  test "returns not found for unknown page" do
    get "/designbook/nope"
    assert_response :not_found
  end
end
