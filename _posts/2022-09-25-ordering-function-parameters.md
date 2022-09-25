---
layout: post
title:  "Ordering Function Parameters"
date:   2022-09-25 01:00:00
tags: blog functional-programming
---
This note is about principles guiding function parameter order. As the object
of study, let's take the following function:

```typescript
// Hardcodes stylesheet styles into HTML.
function applyStylesInline(css: CSS, html: HTML): HTML
```

I know of two conflicting guidelines for the order:
- Context first
- Input then output

## Context first
In languages with functional operators and FP patterns, it's a good idea to
apply context-like arguments first. In the case of `applyStylesInline`, it
might mean that `(css, html)` is preferred over `(html, css)`.

The reason for this is partial application convenience. Partial application
often appears when we are mapping over a functor, for example:

```haskell
applyStylesInline :: CSS -> HTML -> HTML
codeSnippets :: [HTML]

map (applyStylesInline css) codeSnippets
```

### Context is contextual

There is a possibility that what's considered to be the context changes, e.g.,
we could just as well map over stylesheets, `fmap (\css -> applyStylesInline
css codeSnippet) stylesheets`. It's up to the programmer's discretion to figure
out which one is more likely.

## Input then output

In imperative, mutable languages like C, where function arguments are also used
for output values, it is a good convention to put input parameters before
  output ones, like so:

```c
void apply_styles_inline(const CSS* css,
                         const HTML* input_html,
                         HTML* output_html)
```

This convention is useful, because we can more easily reason out which
parameters will change at call sites.
