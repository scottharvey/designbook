---
title: How to use Designbook
order: 999
---

# How to use Designbook

Designbook is the living documentation for this product’s design system. It is meant for reading — not for managing content through an admin UI.

## Finding your way

- Use the **sidebar** to move between sections and pages.
- Use **search** at the top of the sidebar to find pages by title or content.
- Use **Previous / Next** at the bottom of a page to read in order.
- Follow **links inside pages** to related topics. Some pages also show **Linked from** when other pages point here.

## What you’ll find here

Documentation covers the design language as a whole:

- Philosophy and principles
- Foundations such as typography and color
- Components and patterns
- Live examples where available

Treat this as the shared reference for designers and engineers.

## Reading tip

Prefer the written principles and live examples over screenshots. When a page embeds a component preview, that preview is live — it reflects the current implementation.

## Writing pages (for authors)

Pages are Markdown files in Git. Each page starts with frontmatter:

```yaml
---
title: Buttons
order: 10
---
```

- `title` is required
- `order` is optional and controls sorting within a section
- Folders become URL paths and sidebar sections

### Linking

Prefer relative Markdown links so docs stay readable in Git:

```md
See [Typography](../foundations/typography.md)
```

Absolute paths under the Designbook mount also work.

### Callouts

```md
:::note
Helpful context that is not a warning.
:::

:::tip
A practical suggestion.
:::

:::warning
Something easy to get wrong.
:::

:::principle
A design principle worth calling out.
:::
```

### Live components

If Lookbook is available, embed a preview:

```md
:::component ui/badge
:::
```

Use the Lookbook preview path (for example `ui/badge`), not the full inspector URL.

### Screenshots

```md
:::screenshot /path/to/image.png
:::
```

## If something looks wrong

- Missing pages usually means a Markdown file is missing, misnamed, or has invalid frontmatter.
- Broken component embeds usually mean the Lookbook preview path is wrong, or Lookbook is not mounted.
- Search only indexes the current docs tree — new files appear after refresh in development.
