# Changelog

## Unreleased

- Add docs image assets folder (`docs/designbook/assets`) served through Designbook auth
- Improve reading experience with page metadata, sticky table of contents, and book-like typography
- Expand documentation directives (`info`, `success`, `implementation`, `accessibility`, `best-practice`, `anti-pattern`, `future`, and related)
- Add related pages, automatic backlinks (“Referenced by”), and pattern document support
- Add collapsible sidebar with remembered state, keyboard navigation, and command palette (`⌘K` / `Ctrl+K`)
- Add design token rendering from `config/design_tokens.yml`
- Enrich Lookbook embeds with description, source/open links, and optional parameter controls
- Add helpers: `designbook_link`, `designbook_url`, `designbook_page`, `designbook_component_link`, `designbook_token_link`
- Polish: theme toggle, copy code/heading links, 404 page, search highlighting, focus and ARIA improvements
- Add markdown-first docs catalog with frontmatter parsing, ordering, backlinks, and grouped search
- Add directive system with built-in callouts, principles, screenshots, and Lookbook component embeds
- Add safe directive rendering pipeline with sanitization and relative link rewriting
- Add install and Lookbook bridge generators with idempotent behavior and post-install notes
- Add unit and integration test coverage for renderer, catalog, routing, and search
