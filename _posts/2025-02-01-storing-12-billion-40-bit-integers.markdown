---
layout: post
title:  "Storing 12 billion 40-bit integers"
date:   2025-02-01 00:59:59
math: true
tags: data-structure
---
## Problem

This note is about a problem of efficiently storing 12 billion account IDs,
which are 40-bit integers. I mean to use this set of integers in an
event-processing service to filter out events that do not belong to an account
in the set.
I compare three popular data structures:

- Roaring bitmaps
- Bloom filters
- Elias-Fano encoding

## Theoretical limits

Let’s calculate the theoretical number of bits needed to represent the set.
Let’s call $$n = 2^{40}, k = 1.2 \cdot 10^{10}$$.
We have $${n} \choose {k}$$
combinations.
[We can approximate the binomial coefficient using a formula from Wikipedia](https://en.wikipedia.org/wiki/Binomial_coefficient#n_much_larger_than_k)
and, to get storage requirements, take its base-2 logarithm, which gives us:

$$k \left(\lg \frac{n}{k} + \lg e - \frac{k}{2n}\right)$$

This tells us that for each of the $$k$$ numbers,
we’ll use around 8 bits (the formula in the parentheses is a bit smaller than 8)
in the optimal case. So, 12 GB in total.

## Roaring bitmaps

One popular data-structure we could consider for this problem is [a roaring bitmap][roaring].
It scales with the size of its contents and enables efficient query
(logarithmic complexity) and set operations.

Since the density of our data set is much lower than 16
(it’s $$\frac{k}{n} \approx \frac{1}{91}$$),
Roaring will use packed arrays.
They are still relatively dense, so Roaring will use 2 bytes per element.
That’s double of what an efficient encoding would use.

## Bloom Filter

[Bloom filters][bloom] are a second structure that comes to my mind for
efficient storage.
Its special property is that it’s probabilistic: there’s a chance of false
positives, where the membership test returns true for elements not in the set.
To store 12 billion numbers and have a one in quadrillion chance
($$10^{-12}$$) of an FP,
[we’d need 80 GB](https://hur.st/bloomfilter/?n=12G&p=0.000000000001&m=&k=).
Not great.

In a finite-universe like ours,
there’s a trick to more efficiently decrease the chance of errors by chaining
bloom filters.
Instead of creating a single filter with a low error-rate, we can create a
filter with a high error-rate and then another filter that encodes false
positives. For example:

- Create a filter for 12 billion elements with $$0.1\%$$ FP rate: 20.1 GiB.
- Create a filter for around 1.1 billion false positives ($$0.1\%$$ of $$2^{40}$$)
  with $$0.1\%$$ FP rate: 1.84 GiB.
- Create a correcting vector to correct for the previous filter.
  12 million of 40-bit integers will take 0.06 GB.

All in all, we are using about 24 GB. Perhaps it can be optimized further,
but overall, we are using compression comparable to Roaring.

## Elias-Fano

[Elias-Fano encoding][elias-fano] is an encoding for integer numbers that is
close to optimal and allows for efficient query operations (constant time).
I considered it last, because I was unaware of it before considering this
problem, but it seems perfect for my use-case as Elias-Fano uses
$$k \left(\lceil{\lg\frac{n}{k}}\rceil + 2\right)$$ bits, which in our case means
9 bits per element. That’s just one bit more per element than a theoretically
optimal encoding.

Elias-Fano is also easy to explain and implement:

1. Sort the numbers.
2. Split numbers into $$\lceil \lg \frac{m}{k} \rceil$$ upper bits and
   $$\lceil \lg k\rceil$$ lower bits.
3. Store lower bits in a vector without any special encoding.
4. Group upper bits by equality (the sorting step makes it trivial), store
   lengths of buckets using unary encoding with zeros as separators.

[bloom]: https://en.wikipedia.org/wiki/Bloom_filter
[elias-fano]: https://www.antoniomallia.it/sorted-integers-compression-with-elias-fano-encoding.html
[roaring]: https://roaringbitmap.org/
