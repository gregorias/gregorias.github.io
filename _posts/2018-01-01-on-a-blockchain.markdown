---
layout: post
title:  "Tips for reading the blockchain hype"
date: 2018-01-01
---
"Blockchain" is my candidate for the word of 2017. Almost every week, I read
news about new blockchain-based business ventures that are to disrupt or at
least significantly improve an area of business. Even a [nearby canton, Zug, is
offering identity-management on a
blockchain](https://cryptovalley.swiss/swiss-city-zug-offer-blockchain-based-digital-identity-residents/).
The volume, the money involved, and the highly-enthusiastic tone of these news made
me worry.
Was I [missing something
out](https://en.wikipedia.org/wiki/Fear_of_missing_out)? I presume that many
people are also worried by this situation: the sensation of not comprehending
what's happening, but also seeing other people hysterical about it.
This kind of environment is like being in a middle of another [tulip
bubble](https://en.wikipedia.org/wiki/Tulip_mania) -- dangerously congenial to
rash decisions and bubbles[^tea].

I'd like to alleviate some of these worries and provide some tools for
interpreting the flood of blockchain news. Tools that will help see past the
hype and better understand what is going on.

# A blockchain is a data structure

If there's one thing that I'd like you to get out of this article is that the
answer to the question "What is a blockchain?" is "It's a data structure -- a
way to store data."

A data structure defines two things: how it represents data and what kind of
things we can do with it.  Consider the problem of saving the account status of
all bank customers. A data structure for this problem has to allow us to query
and to update the status of an account.

One solution would be to keep all pairs of the customer ID and account status in
a traditional database. Querying is simple -- find the pair with the
ID that you are looking for and just read the status. Updating requires
modifying the account status, operationally this could be done by deleting the
old entry and adding a new one.

A different, blockchainy way to approach this problem would be to represent the
underlying data as a sequence of update operations. For example, let's say that
I, Grzegorz, begin
with $10 in the bank and later transfer $5 to a friend's account -- Robert. We
would represent this as two operations:

<figure>
<img src="/images/blockchain.png" alt="Two orange rectangles connected by an arrow. The rectangles contain the information about operations." />
</figure>

In this solution, updates are additions of operations to our sequence.
Querying the account status is more complicated as it requires to follow all
operations relevant to the sought account and combining them together.

These kind of data structures that create a sequence of blocks are blockchains.
Although in our case we have used the blockchain for representing a ledger, the
content of blocks can be arbitrary, e.g. pictures of cats are also fine.

And that's the gist of it.

# Unwarranted claims and nebulous terms

We can now go to the core sin of any hype -- unwarranted claims. Consider for
example [this statement](https://hbr.org/2017/01/the-truth-about-blockchain):

> Similarly, blockchain could dramatically reduce the cost of transactions. It
> has the potential to become the system of record for all transactions. If that
> happens, the economy will once again undergo a radical shift, as new,
> blockchain-based sources of influence and control emerge.

Can you explain how the cost-reduction will happen and why is blockchain so
essential? I can't, and the authors don't explain it either. It's also almost never
possible to fully falsify such statements because what is meant by "a blockchain" is
never fully clear. It is always something between the pure blockchain as described above and Bitcoin.

Why is it that way? The fascination with blockchains stems from Bitcoin's
success. Bitcoin uses blockchain as its primary data structure. The underlying
argument for any blockchain claim often goes like this:

1. Bitcoin uses blockchain, and
2. Bitcoin is A, therefore
3. Blockchain is A.

When presented as a syllogism, the fallacy is clear. Quite often a stronger
version is presented:

1. [*The blockchain is perhaps the main technological innovation of
   Bitcoin.*](https://www.investopedia.com/terms/b/blockchain.asp)

Which is simply not true. Bitcoin is, in fact, a collection of multiple ideas
that are essential for its success, ideas that have mostly been present in the
academia since the 80s or the 90s.
["Bitcoin's Academic Pedigree"](https://queue.acm.org/detail.cfm?id=3136559)
does an excellent job of explaining the technological provenance of all the
parts that constitute Bitcoin as we know it: blockchain is only a small part of
it.

The situation is like confusing a smartphone with a phone motherboard. The
motherboard and what's on it is an essential part of a phone's success, but it's
far from being the only essential part.

<figure>
<img src="/images/motherboard-vs-smartphone.png" alt="A picture with a phone motherboard and a few smartphones." />
</figure>

Whenever you read an article about blockchain, almost always "blockchain" means
the data structure plus some ideas that are used in Bitcoin, like proof-of-work,
Merkle-hashes etc.
Just like people talking about a phone's board often mean the motherboard with
all that's on it -- CPU, memory, etc.
[But just because some ideas are taken from Bitcoin, it doesn't mean that all
Bitcoin properties will be present in the new blockchain-based system.](https://www.forbes.com/sites/francescoppola/2016/06/13/blockchain-meh/#625aa15d35ef)

I found this fallacy most visible in the [Investopedia's article on the
blockchain](https://www.investopedia.com/terms/b/blockchain.asp). Claims like
*creates an indelible record that cannot be changed*,
*these transactions are immutable, meaning they cannot be deleted*,
*they remain meddle-proof*,
*gets a copy of the blockchain, which is downloaded automatically* are
properties that the current deployment Bitcoin deployment satisfies but do not
necessarily apply to a blockchain. In particular, a blockchain-based solution can
not satisfy all Bitcoin's properties, otherwise, it would just be another Bitcoin
currency.

# Blockchain blindness

The other problem with the current hype is that people are so infatuated with
blockchain that they see every new solution to a problem as a choice between
going with the old system or switching to a Bitcoin-like blockchain. This is a
false dichotomy and a blockchain is often an overkill.
[Many](https://blog.apnic.net/2017/12/14/dont-get-caught-blockchain-hype/)
[articles](https://www.multichain.com/blog/2015/11/avoiding-pointless-blockchain-project/)
[point](https://blog.xot.nl/2017/09/06/blockcerts-using-blokchain-for-identity-management-is-mostly-ridiculous/)
that out. It's like buying an iPhone just for its LED lamp.

<figure>
<img src="/images/smartphone-torch.jpg" alt="A picture of an iPhone with the LED lamp on" />
<figcaption style="text-align: center">Using blockchain is like using an iPhone when you just need a torch.</figcaption>
</figure>

For example, a common worry is that some current solutions are closed and
unverifiable by external parties. Well, if that's the case, then
making the current database public and available for download is the easiest
solution. Revamping the entire system to be blockchain-based is not needed.

The silver lining here is that the blockchain-mania got people interested in
technical solutions to their problems. The mania gives the necessary push for
decision-makers to fix current, legacy systems.
It's an opportunity, and I encourage more technically minded folks to use this
enthusiasm to familiarize people with more stable technologies that would be
more appropriate.

# A final warning

You should now be well-equipped to face blockchain news and sieve-out or
at least corral the hype. I'd like to warn you not to go to the other extreme
and conclude that any blockchain-related endeavour is overblown. After all,
Bitcoin uses a blockchain and is highly successful. [There are also projects,
which address valid concerns and where blockchain is the best
approach](https://www.multichain.com/blog/2017/11/three-non-pointless-blockchains-production/).

[^tea]: [The bright side of any bubble is that you get to hear about ridiculous stock market stories like this one.](https://www.bloomberg.com/news/articles/2017-12-21/crypto-craze-sees-long-island-iced-tea-rename-as-long-blockchain?utm_source=hackernewsletter&utm_medium=email&utm_term=fun)
