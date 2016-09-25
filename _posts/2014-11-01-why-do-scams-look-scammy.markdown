---
layout: post
title:  "Why do scam e-mails look scammy?"
date:   2014-11-01 16:00:00
uses_mathjax: true
tags: mathematics technical
category: mathematics
---
While perusing HN I noticed an article from Microsoft researcher Cormac Herley
[Why do Nigerian Scammers Say They are from Nigeria?][whyfromnigeria] . It's
quite simple to read and an entertaining article which builds a mathematical
model to explain nonintuitive behaviour of internet scammers.

The scam model
==============

What does scamming entail? First scammer can attack a population of $$ N $$
people, where there are $$ M $$ viable targets. We assume that viable target
once attacked will always produce $$ G $$ money, however every attack costs $$
C $$.

An attacker obviously can not distinguish beforehand who's viable and who's
not, but he has a viability metric of each target a score which tells him how
likely it is that given target is viable. This metric is an abstraction of an
idea that scammer might for example know age of a target and assume that older
people are more gullible.

Such metric allows us to model our attacker as a binary classifier and use
typical machine learning tools to analyse his behaviour.

ROC curve
=========

The primary tool used to understand a scammer is a ROC curve. It is a curve
which shows what kind of true posivite rate we can achieve (percentage of found
viable targets in viable population) if we allow given false posivitive rate
(percentage of nonviable population classified as potential targets). An example
of a ROC curve looks like this:

![ROC Curve](/images/ROCCurve.png)

Usually in the beginning gaining larger positive rate is easy, but as the
scammer tries to catch as many viable targets as possible he has to deal with
the fact that he will get many more non-viable targets for one viable. 

How does it affect the scammer?
=============================

If the cost of attacking is low (for example for a simple e-mail spam) then the
ROC curve might not matter, but if attacking everyone is nonviable then our
scammer has to choose where he wants to place himself. If $$ G $$ increases
and/or $$ C $$ decreases his optimal attack point moves further to the
upper-right, attacking bigger portion of the population, scamming more targets
and annoying bigger percentage of nongullible population.

The most important factor in this model is the density of targets in population
$$ d = \frac{m}{n} $$. It turns out that the attacked population at optimal
point decreases unproportionately to the decrease of density. The paper even
shows example where a 10x drop in density results in 1000x drop of attacked
population size. This phenomena prevents the scammer from attacking any
meaningful portion of the population if the density of gullible people is low
and cost is nonnegligible.  This also means that he will attack only a very
small fraction of viable targets, if he decides to attack at all.

This explains why spammers say they are from Nigeria or other western african
country. They are trying to ensure that only the most gullible will respond,
thereby artificially increasing the density of the population. Spam is cheap,
but handling a target is not. Scammers effectively run a 2-tier classifier,
which somewhat rescues them from originally hopeless situation.

The density drop properties also explain why we don't see targeted scams that
often, where spammers try to fish people with specific illness out.

AUC meaning derivation
======================

As a last note I wanted to write derivation of the following fact mentioned in
the text: 

> The Area Under the Curve (AUC) [ROC Curve] is the probability that
> the classifier ranks a randomly chosen true positive higher than a randomly
> chosen false positive. 

I wasn't aware of this before and it seemed nonintuitive to me so I verified it.

The ROC curve can be described in terms distribution functions of true and false
positive rates. Let $$r(x)$$ be the curve and $$x$$ be the false positive rate.
Then:

$$
r(x) = cdf_t\left(cdf_f^{-1}(x)\right)
$$

The AUC is given by:

$$
\int_0^1 r(x) = \int_0^1 cdf_t\left(cdf_f^{-1}(x)\right)
= \int_{-\infty}^\infty cdf_t(y) cdf_f'(y) dy
= \int_{-\infty}^\infty cdf_t(y) g_f(y) dy
$$

I used the variable substitution formula to arrive to the last intergral.

Now let's calculate the probability that after taking two viability metrics, one
from the pool of viable target the other from nonviable, we will the first one
will be lower. Let's name both random variables as $$X, Y$$. I assume that
Fubini's theorem holds.

$$
P(X<Y) = \int \mathbb{1}_{x<y} g_t(x) g_f(y) d (x,y)
= \int_{-\infty}^\infty g_f(y) 
\left(\int_{-\infty}^\infty \mathbb{1}_{x<y} g_t(x) dx\right) dy
= \int_{-\infty}^\infty g_f(y) cdf_t(y) dy
$$

As we can see both are equal. An explanation is due as to what every symbol
really means. $$g_t, g_f$$ are density functions of viability metrics in viable
and nonviable population. We may also notice that
$$ \int_{-\infty}^\infty cdf_t(y) g_f(y) dy = E\left(cdf_t(Y)\right), Y$$ being
random variable of viability metrics in nonviable population.

[whyfromnigeria]: http://research.microsoft.com/pubs/167719/WhyFromNigeria.pdf
