---
title: Typography
order: 10
status: Stable
version: 1.1
tags:
  - foundations
  - reading
updated: 2026-07-27
---

# Typography

Typography should be calm, readable, and information-dense.

## Voice of the page

:::principle
Choose typefaces that disappear — the reader should notice the content, not the font.
:::

## Hierarchy

Use fewer sizes, then rely on weight and spacing to create hierarchy.

### Body copy

Keep line length near the reading measure. Prefer long-form serif for prose, and a quieter sans for chrome.

### Code

```ruby
class TitleComponent < ViewComponent::Base
  def initialize(text:)
    @text = text
  end
end
```

## Guidance

:::best-practice
Set a clear measure, generous leading, and predictable heading rhythm before introducing decorative type.
:::

:::anti-pattern
Do not invent a new type scale on every page. Share the foundation tokens instead.
:::

:::note
The system font stack ensures consistent rendering across platforms without external font loading.
:::

Related: [Philosophy](../philosophy/index.md) · [Color](./color.md) · [Tokens](./tokens.md)
