---
title: Color
order: 11
status: Stable
version: 1.0
tags:
  - foundations
  - colour
updated: 2026-07-27
---

# Color

Color should support hierarchy and meaning without competing with content.

## Palette

Prefer a small set of shared tokens over page-local hex values.

:::tokens colours
:::

## Usage

:::accessibility
Never rely on colour alone to communicate state. Pair colour with label, icon, or text.
:::

:::implementation
Pull values from `config/design_tokens.yml` rather than hardcoding them in components or markdown.
:::

See also [Typography](./typography.md) and [Tokens](./tokens.md).
