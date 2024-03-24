---
layout: post
title:  "Book review of Reisig’s “Understanding Petri Nets”"
date: 2016-10-21
tags: blog review
---
![Understanding Petri Nets' book cover](/images/2016/10/upn.jpg){: .left}

"Understanding Petri Nets" by Wolfgang Reisig is an academic introduction to the
topic of Petri nets. I decided to read it because Petri nets were a thing that I
have heard about a few times, but never really found out what those nets are; I
didn't want to miss out on anything useful. This review should help you decide
whether this book will be useful for you too.

23 chapters, grouped into 3 main parts and a conclusion, present a range of
topics on Petri Nets. They start by explaining what Petri nets are — a
mathematical way of modeling distributed systems (but they can also model things
like business processes) — and what can they do. There is a focus on elementary
nets, with a small consideration for 1-bounded elementary nets and general nets.
Other kinds of nets are mostly just mentioned.

After showing the toy to the reader, the second part dives into interesting
properties of Petri nets, their relationships and theorems. The third part
finishes the introduction by showing use-cases of Petri nets in scenarios that
might be closer to some real-world problems, like network algorithms or
parallelized hardware.

Each chapter is relatively short and to the point. Reisig discusses main ideas
and concepts, shows main theorems, sometimes with a proof if it is short. Every
chapter ends with a small set of exercises that can be done within an hour.
Those exercises and the book as a whole require only a fundamental understanding
of linear algebra. However, do not think that all exercises are trivial.  Some,
like those requiring proof of a theorem from a chapter, might require longer
thought, and doing them creates a deeper understanding of the topic.

In line with the introductory character of his book, Reisig provides a number of
references to more advanced sources for curious readers as he goes with the
material.

As for the topic of Petri nets itself, they're definitely a fun tool to use. If
I can show something as a graph with dynamic tokens, instead of abstruse
symbols, then count me in, right? Graphs allow clear representation of some
problems that may be more intuitive than other approaches, especially if you
have to explain it to less math-savvy people. Nets have a deeper theory behind
them, so we don't sacrifice proving power for graphical representation. However,
they seem to be mostly useful for people who are really serious about the formal
correctness of their systems as I can imagine that creating a model of a real
world system as a Petri Net takes a lot of time. More than other informal or
symbolic reasoning approaches that are more often used.

I wholeheartedly recommend "Understanding Petri Nets" to anyone interested in
getting a fundamental knowledge about Petri nets. The book can be read quickly
as it is 200 pages with lots of graph images. After the lecture we can feel the
understanding of Petri nets. Just like the title would suggest.
