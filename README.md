# Designbook

Designbook is a mountable Rails engine for markdown-first design documentation.

It provides a reading experience closer to Rails Guides or Polaris than an admin console:

- Markdown pages with YAML frontmatter
- Automatic sidebar, table of contents, and prev/next navigation
- Page metadata, related pages, and automatic backlinks
- Custom documentation directives
- Design token rendering from YAML
- Lookbook embeds with optional controls
- Client-side command palette search
- Generators for install and Lookbook bridge wiring

## Installation

Add this line to your application's Gemfile:

```ruby
gem "designbook"
```

Then run:

```bash
bundle install
```

## Setup in host app

```bash
bin/rails g designbook:install
bin/rails g designbook:install_lookbook_bridge
```

Restart your server and visit `/designbook`.

## Configuration

`config/initializers/designbook.rb`:

```ruby
Designbook.configure do |config|
  config.docs_path = Rails.root.join("docs/designbook")
  config.parent_controller = "ActionController::Base"
  config.mount_path = "/designbook"
  config.design_tokens_path = Rails.root.join("config/design_tokens.yml")

  # Optional host auth hook
  # config.authenticate = -> { authenticate_admin! }
end
```

## Frontmatter

```yaml
---
title: Buttons
status: Stable
version: 1.1
tags:
  - forms
  - actions
updated: 2026-07-27
order: 10
---
```

Missing optional fields are omitted from the page metadata.

Pattern pages live under `patterns/` or set `type: pattern`.

## Custom directives

Built-in callouts include `note`, `tip`, `info`, `warning`, `success`, `principle`, `implementation`, `accessibility`, `best-practice`, `anti-pattern`, and `future`.

Authors write them in Markdown:

```md
:::best-practice
Prefer shared tokens over page-local values.
:::
```

To add a new directive, register it once in an initializer. Authors then use the fence syntax above:

```ruby
Designbook.register_directive("badge") do |argument, body, context|
  "<aside class='badge badge-#{argument}'>#{body}</aside>"
end
```

Then in docs:

```md
:::badge primary
Shipped
:::
```

Directive block parameters:

- `argument` - directive argument text after the directive name
- `body` - directive body text between opening and closing fences
- `context` - `Designbook::DirectiveContext` with `current_slug`, `catalog`, and `configuration`

### Tokens

```md
:::tokens colours
:::
```

### Components

```md
:::component button/default
name: Button
description: Primary action
source: app/components/button_component.rb
params:
  label: Save
:::
```

## Images

Put files in `docs/designbook/assets/`. Designbook serves them at `/designbook/assets/...` using the same authentication as pages.

```md
![Button anatomy](assets/button-anatomy.png)

:::screenshot assets/button-anatomy.png
:::
```

Do not put private Designbook images in `public/`.


Use these from the host app when linking into Designbook:

- `designbook_page(slug)`
- `designbook_link(slug, text = nil)`
- `designbook_url(slug)`
- `designbook_component_link(preview_id)`
- `designbook_token_link("colours.accent")`

## Security model

- Markdown is rendered with raw HTML disabled.
- Directive output is sanitized with an allowlist before insertion.
- Internal `.md` links are rewritten to mounted Designbook routes.

## Development checks

```bash
bundle exec rake test
bin/rubocop
```
