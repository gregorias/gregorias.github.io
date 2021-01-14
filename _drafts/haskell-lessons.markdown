---
layout: post
title:  "Haskell Lessons"
tags: blog
---

## Style Guide

### Use Ormolu to format Haskell file

Consistent, readable style is good. Beyond that I don't care.

#### Set up Ormolu in Git's pre-commit

Automate formatting

### Record Field names

Record field names should start with lowercase first letters of the constructor
followed by CamelCase, e.g.,

    data WithholdingTax = WithholdingTax
      { wtDate :: Day,
        wtDividendPerShare :: MonetaryValue
      }

The prefix help prevent ambiguous selector names, which arises often.

The alternative of allowing `DuplicateRecordFields` causes headache when
there's a conflict in one file or forces disambiguation, where I might not want it.
