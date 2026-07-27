require "test_helper"

module Designbook
  class MarkdownRendererTest < ActiveSupport::TestCase
    test "renders directives and rewrites relative links" do
      renderer = MarkdownRenderer.new

      markdown = <<~MD
        # Typography

        :::note
        Keep typography calm.
        :::

        See [Philosophy](../philosophy/index.md)
      MD

      html = renderer.render(markdown, current_slug: "foundations/typography")

      assert_includes html, "db-callout-note"
      assert_includes html, "href=\"/designbook/philosophy\""
      refute_includes html, ":::"
    end

    test "supports fenced code blocks after directives" do
      renderer = MarkdownRenderer.new

      markdown = <<~MD
        :::principle
        Design for understanding.
        :::

        ```ruby
        puts "hello"
        ```
      MD

      html = renderer.render(markdown, current_slug: "index")

      assert_includes html, "db-principle"
      assert_includes html, "<pre><code class=\"highlight\""
      assert_includes html, "puts"
    end

    test "does not render arbitrary raw html from markdown" do
      renderer = MarkdownRenderer.new

      markdown = <<~MD
        <script>alert("xss")</script>
        # Hello
      MD

      html = renderer.render(markdown, current_slug: "index")

      refute_includes html, "<script>"
      refute_includes html, "alert(\"xss\")"
    end
  end
end
