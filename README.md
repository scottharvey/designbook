# Designbook

Designbook is a mountable Rails engine for markdown-first design documentation.

It provides:

- A `/designbook` reading experience with sidebar navigation
- Frontmatter-driven metadata (`title` required, `order` optional)
- Markdown rendering with syntax-highlighted code blocks
- Custom directives (`:::note`, `:::warning`, `:::tip`, `:::principle`, `:::screenshot`, `:::component`)
- In-memory catalog, backlinks, and grouped full-text search
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

  # Optional host auth hook
  # config.authenticate = -> { authenticate_admin! }
end
```

`config/initializers/designbook_lookbook_bridge.rb`:

```ruby
Designbook.configure do |config|
  config.lookbook_preview_base_path = "/lookbook/inspect"
end
```

## Custom directives

Register custom directives from an initializer:

```ruby
Designbook.register_directive("badge") do |argument, body, context|
  "<aside class='badge badge-#{argument}'>#{body}</aside>"
end
```

Directive block parameters:

- `argument` - directive argument text after the directive name
- `body` - directive body text between opening and closing fences
- `context` - `Designbook::DirectiveContext` with `current_slug`, `catalog`, and `configuration`

## Security model

- Markdown is rendered with raw HTML disabled.
- Directive output is sanitized with an allowlist before insertion.
- Internal `.md` links are rewritten to mounted Designbook routes.

## Development checks

```bash
bundle exec rake test
bin/rubocop
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
