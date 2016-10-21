---
layout: post
title: "The joy of static type systems and testing"
date:  2014-11-16 19:00
tags: programming software development
---
I love programming, for one it's an extremely practical tool allowing me to
harness the ever growing power of automatic computation and control (though,
admittedly, my abilities only allow me to use a very small part of it :)). But
it's not just the practicality that draws me to it, but also its elegance. It
feels very satisfying when I run my finished program and see growing log lines
telling me everything goes as planned. It is a similar to the satisfaction one
feels when watching [a complicated Goldberg machine][legogoldberg] or writing a
mathematical proof.  The sensation of knowing everything that's happening and
trusting it. On the other hand I dislike it when something breaks it breaks the
illusion, the sense of elation. I feel discomfort when I don't trust the
software, especially my software.

I didn't always feel that way. I remember the days when my programs were mostly
one source code file projects for either a programming competition or a simple
tool to do one specific task. I knew about testing and heard multiple times how
it is important, but didn't care much. I mostly did stuff in C++, because it is
the language of algorithmic competitions, but I felt that it wasn't a really
elegant language. It often forced me to do stuff its own way and its template
error messages were so cryptic that I usually resorted to binary search to find
what was wrong (now I know I should have used clang). Python was the rave.
Simple, powerful, and dynamic.

Then the university came, now my projects were graded and I had to program what
other people required, up to specification. I still didn't think much of
automatic testing. Just ran the program, typed some inputs and saw if they are
correct. I started noticing that I liked designing the architecture, finding out
what objects and functions would be best to represent the problem and how would
they fit together. Are they easy to change, replace?  Are they really simple
enough or should I break them more? Python was getting on my nerves, the bigger
the project grew the more errors I made, which wereonly caught on runtime.
4-tuples to a function where I expected 5-tuples etc. So I started writing a lot
of assertions, but only for a short moment. That was the time hen I realised
that I simply preferred statically typed languages.

Occasionally I hear people complain about static typing being cumbersome and
restrictive. For critics they feel they get in the way. I agree that in small
projects, scripts building something in Java (although perhaps this is a poor
example of good typing system) is a waste of time, though a small one. When you
write a program you already have to have a mental model in your head what kind
of data you expect and what kind of data you will want out. Typing annotations
cost only a few extra keystrokes to externalise this mental model, those
keystrokes allow compiler or interpreter to check for you now and for you in the
future whether everything is ok. What those programmers who complain about
typing system don't realise is that when they write types they basically write
proofs, just like a mathematician does. Type system are simply logical proof
system, benefits of which are enormous. Expressive and rich systems are
wonderful tools for software verification, they catch many errors, common in
dynamically typed systems, early. This is indispensable in large project where
either the programmer forgets his mental model, or didn't have it at all,
because someone else works with his code. They also provide a great
documentation tool. I realised that when I did an interpreter project in Haskell
and noticed that sometimes I just needed to look at the type of the function to
realise that that is what I want to do.

Despite much progress in the field, typing systems can only do so much, they
provide a lot for low cost, but if you really want to be sure you need to bring
in the big guns of software verification tools. They often take a lot of time,
require additional specification and are usually unpractical for large projects.
The poor man's verification is testing. Tests can not prove a program is
correct, but they check whether they can dectect bugs. It can be tedious, but
this is not their only function. Test driven development is a software
engineering method which teaches an approach of writing tests first for given
module of code. It helps enormously with design, because it forces you to
consider the external behaviour and usage of your code. You want to spent as
little time writing tests as possible so you strive on making the tested module
as small as possible and externalise it's dependencies so that you can easily
mock, stub or fake them. It was the TDD that taught me about the D in SOLID
principles (that and discovery of guice library in Nebulostore). I don't use TDD
approach on a daily basis, but I always remember its lessons.

I am always surprised and shocked when I hear negative attitudes about testing,
because I have never seen a well-maintainable large project which would
disregard them. Those that do often pay the price of large number of bugs,
regressions and long-development time. Although this is instinctively obvious,
the trade is often made, because of time constrains. Why bother with tests when
we have features to do? This is often a bad trade, a code debt which only
increases over time. Some examples of its effects I have seen are:

* Almost complete lack of unit tests. Why? Because programmers felt it wasn't
  their job to do them as they have more important stuff to do. It was the job
  of QA, but since QA deals mostly with scripts and doesn't close ties
  to development team they don't care. The attitude that tests are some kind of
  degrading tasks caused this project to be tightly coupled, hard to change and
  filled with unnecessary bugs and regressions.
* Tests which don't really check anything. On a different project I encountered
  a bug after bug, which was surprising to me, because
  tests were passing (I was young and naive then). I was new to the project and
  felt lost, because I was never sure whether my change would break something or
  not. Also later I realised that lack of clear vision of what kind of
  functionality is expected, which would be forced with proper testing
  infrastructure, caused this project to drift, never realising its potential.

That's why I'm always happy to hear about projects which take this matter
seriously, some notable examples which show a good model to follow:

* [SQLite][sqlite]. I recommend reading this. It is a holy \*\*\*\*
approach to testing, but it is probably a reason why this project is so
successful.
* [Testing distributed system with deterministic simulation][simulation].
Explains how one can reliably test a distributed system. These guys built their
database in such a way that it's possible to run it in a deterministic way so
that they can easily debug it later. Repeatability is an important aspect of
testing.
* Netflix's code monkey. A robot shutting down *production* servers to check
whether the system can handle failure. It shows how much trust and importance
they put into reliability of their software.

Having talked about the practical value in both tools I also want to say again
that those things are not only practical tools, but have also emotional value.
If properly embraced they can be a source of joy. For one thing they allow the
programmer to build trust to their work, a feeling of completion. On a deeper
level a well typed module can bring the feeling of satisfaction one feels after
solving a puzzle, after all types are like mathematical proofs.

[legogoldberg]: https://www.youtube.com/watch?v=sUtS52lqL5w
[sqlite]: http://www.sqlite.org/testing.html
[simulation]: https://www.youtube.com/watch?v=4fFDFbi3toc
