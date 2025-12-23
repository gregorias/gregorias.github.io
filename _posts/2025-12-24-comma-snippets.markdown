---
layout: post
title: "Comma Snippets"
date: 2025-12-23 02:00:00
tags: keyboard
---

Snippets are a handy productivity tool.
However, if you use snippets a lot, you may run into an aliasing problem:
something you have typed turns out to be a registered snippet.
Your snippet engine fires, causing confusion.

I found that using a comma as the leader key for my snippets solves
the ambiguity really well. Comma has all the desirable properties:

- Comma is easily reachable as a key. No need for chording or stretching.
- In most text, comma is followed by a space. Unless you are working with
  CSV files, it’s unlikely you will ever run into a conflict.

I use such comma-based snippets for all kinds of things:

- `,mL` turns into a Markdown link with the URL from my clipboard `[](CLIP)`.
- Math and special characters: `,neq` → ≠, `,rarr` → `→`, `,bp` → ‱.
- `,shrug` → “¯\\_(ツ)\_/¯”.

## Diacritics

I have one major exception to the comma-as-a-leader key style, and those
are diacritics.
For diacritic characters, I follow the pattern `<base-character>,<mark>`.
For example, `e,:` turns into `ë`, `a,'` into `á` and so forth.
Quite useful to write that occasional special character.
I do it this way, because it flows more naturally to type the base letter first
and then modify it.
It’s still unambiguous due to that mark after the comma.

BTW, I use [Espanso](https://espanso.org/) for snippets. I wholeheartedly
recommend it.
