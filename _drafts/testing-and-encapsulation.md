---
layout: post
title:  "Testing and Encapsulation"
tags: blog
---

A problem that I consistently encounted is as follows:

I write a module with data and functions but only parts are meant to be used externally. There's a bunch of utilities that support the interface.

It often happens that the interface is rather complex and it would be easier to test the utilities. Testing utilities would also help programming. Often we have a module M, consisting of M1, M2, M3 that we are implementing, and we want to test M1, M2, M3 as we go along

## Best Practices

### Strongly prefer not to make internal functions visible

Hiding complexity makes the module easier to understand and change.

This is also a forcing function that may lead to better, more testable external interface.

### Extract utilities into self-sufficient modules

If you can extract utilities into self-sufficient, cohesive modules, then you can test them, without poluting the module meant for clients.

### Write scaffolding tests

You can make some unit tests for M1, M2, M3 while developing and incorporating them into tests for M when you shut them down.

### Languages Specific Practices

#### Haskell

HSKL has [the `Internal` idiom](https://stackoverflow.com/questions/14379185/function-privacy-and-unit-testing-haskell).
