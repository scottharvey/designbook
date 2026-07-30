---
title: How to use Designbook
order: 999
---

# How to use Designbook

Designbook is the living documentation for this product’s design system. It is meant for reading — not for managing content through an admin UI.

## Finding your way

- Use the **sidebar** to move between sections and pages. Sections collapse, and Designbook remembers your preference.
- Press **⌘K** / **Ctrl+K** to open the command palette and jump to a page.
- Use **Previous / Next** at the bottom of a page to read in order.
- Follow links inside pages to related topics. Pages automatically show **Related pages** and **Referenced by**.

## What you’ll find here

Documentation covers the design language as a whole:

- Philosophy and principles
- Foundations such as typography, color, and tokens
- Components and patterns
- Live examples where available

Treat this as the shared reference for designers and engineers.

## Writing pages

Pages are Markdown files in Git. Each page starts with frontmatter:

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

- `title` is required
- `order` is optional and controls sorting within a section
- `status`, `version`, `tags`, and `updated` appear in the page metadata when present
- Folders become URL paths and sidebar sections
- Pages under `patterns/` (or `type: pattern`) are treated as pattern docs

### Linking

Prefer relative Markdown links so docs stay readable in Git:

```md
See [Typography](../foundations/typography.md)
```

## Directives

Rich blocks use **directives**, not HTML. Write them with opening and closing `:::` fences:

```md
:::note
Your text here.
:::
```

Raw HTML in page bodies is disabled. Custom blocks are added as directives in Ruby; authors always write the Markdown fence.

### Callouts

```md
:::note
Helpful context that is not a warning.
:::

:::tip
A practical suggestion.
:::

:::info
Neutral supporting context.
:::

:::warning
Something easy to get wrong.
:::

:::success
A confirmed good outcome.
:::

:::principle
A design principle worth calling out.
:::

:::implementation
How to build it in the product.
:::

:::accessibility
Requirements for inclusive use.
:::

:::best-practice
Preferred approach.
:::

:::anti-pattern
Avoid this.
:::

:::future
Planned direction.
:::
```

### Tokens

Render values from `config/design_tokens.yml`:

```md
:::tokens colours
:::
```

Show every token group:

```md
:::tokens
:::
```

### Live components

Embed a Lookbook preview. The preview id goes on the opening line; optional YAML in the body sets name, description, source, and params:

```md
:::component button/default
name: Button
description: Primary action control
source: app/components/button_component.rb
params:
  variant: primary
:::
```

### Screenshots

Put image files in `docs/designbook/assets/`. They are served through Designbook auth at `/designbook/assets/...`, not from `public/`.

```md
![Button anatomy](assets/button-anatomy.png)

:::screenshot assets/button-anatomy.png
:::
```

Nested folders work too: `assets/foundations/color-ramp.png`.

## If something looks wrong

- Missing pages usually means a Markdown file is missing, misnamed, or has invalid frontmatter.
- Broken component embeds usually mean the Lookbook preview path is wrong, or Lookbook is not mounted.
- Search and the command palette index the current docs tree — new files appear after refresh in development.
