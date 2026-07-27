require "test_helper"
require "tmpdir"
require "fileutils"

module Designbook
  class CatalogTest < ActiveSupport::TestCase
    setup do
      @tmp_dir = Dir.mktmpdir("designbook-catalog")
      docs = File.join(@tmp_dir, "docs")
      FileUtils.mkdir_p(File.join(docs, "foundations"))
      FileUtils.mkdir_p(File.join(docs, "philosophy"))

      File.write(File.join(docs, "index.md"), <<~MD)
        ---
        title: Intro
        order: 1
        ---

        See [Typography](./foundations/typography.md)
      MD

      File.write(File.join(docs, "philosophy", "index.md"), <<~MD)
        ---
        title: Philosophy
        order: 5
        ---

        :::principle
        Design serves clarity.
        :::

        Link to [Typography](../foundations/typography.md)
      MD

      File.write(File.join(docs, "foundations", "typography.md"), <<~MD)
        ---
        title: Typography
        order: 10
        ---

        :::note
        Typography should be calm.
        :::
      MD

      @previous_docs_path = Designbook.configuration.docs_path
      Designbook.configure { |c| c.docs_path = docs }
      Designbook.reset_catalog!
    end

    teardown do
      Designbook.configure { |c| c.docs_path = @previous_docs_path }
      Designbook.reset_catalog!
      FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
    end

    test "previous and next page boundaries do not wrap" do
      catalog = Catalog.build

      assert_nil catalog.previous_page_for("index")
      assert_equal "philosophy", catalog.next_page_for("index")&.slug
      assert_equal "foundations/typography", catalog.next_page_for("philosophy")&.slug
      assert_nil catalog.next_page_for("foundations/typography")
    end

    test "search strips directive markers from excerpts" do
      catalog = Catalog.build

      result = catalog.search("typography").find { |r| r.page.slug == "foundations/typography" }
      assert result
      refute_includes result.excerpt, ":::"
    end

    test "backlinks are derived from markdown links" do
      catalog = Catalog.build

      backlinks = catalog.backlinks_for("foundations/typography").map(&:slug)
      assert_includes backlinks, "index"
      assert_includes backlinks, "philosophy"
    end
  end
end
