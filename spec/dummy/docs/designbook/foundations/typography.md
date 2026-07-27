---
title: Typography
order: 10
---

# Typography

Typography should be calm, readable, and information-dense.

:::principle
Choose typefaces that disappear — the reader should notice the content, not the font.
:::

```ruby
class TitleComponent < ViewComponent::Base
  def initialize(text:)
    @text = text
  end
end
```

:::note
The system font stack ensures consistent rendering across platforms without external font loading.
:::

Related: [Philosophy](../philosophy/index.md)
