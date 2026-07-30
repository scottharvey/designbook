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

      result = renderer.render(markdown, current_slug: "foundations/typography")

      assert_includes result.html, "db-callout-note"
      assert_includes result.html, "href=\"/designbook/philosophy\""
      refute_includes result.html, ":::"
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

      result = renderer.render(markdown, current_slug: "index")

      assert_includes result.html, "db-callout-principle"
      assert_includes result.html, "<pre><code class=\"highlight\""
      assert_includes result.html, "puts"
      assert_includes result.html, "db-code-block"
    end

    test "does not render arbitrary raw html from markdown" do
      renderer = MarkdownRenderer.new

      markdown = <<~MD
        <script>alert("xss")</script>
        # Hello
      MD

      result = renderer.render(markdown, current_slug: "index")

      refute_includes result.html, "<script>"
      refute_includes result.html, "alert(\"xss\")"
    end

    test "builds a table of contents from headings" do
      renderer = MarkdownRenderer.new

      markdown = <<~MD
        ## Spacing
        ### Rhythm
        #### Exceptions
      MD

      result = renderer.render(markdown, current_slug: "index")

      assert_equal 3, result.toc.length
      assert_equal "Spacing", result.toc.first.text
      assert_includes result.html, 'id="spacing"'
    end

    test "leaves directives inside fenced code blocks as literal text" do
      renderer = MarkdownRenderer.new

      markdown = <<~MD
        Example:

        ```md
        :::note
        Helpful context.
        :::
        ```
      MD

      result = renderer.render(markdown, current_slug: "index")

      refute_includes result.html, "db-callout-note"
      assert_includes result.html, ":::note"
      assert_includes result.html, "Helpful context."
    end
  end
end
