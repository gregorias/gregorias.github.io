---
layout: post
title:  "Investment portfolio selection for greater good"
tags: mathematics investing technical
uses_mathjax: True
category: blog
---
Choosing a portfolio is a daunting task for beginning, amateur investors.
It's difficult to translate rudimentary knowledge and well-meaning, but general
advice, into concrete numbers representing security shares in your account. In
this post, I'd like to broach this subject and present a method of finding a
portfolio that maximizes expected return for given variance level, which
we'll associate with risk, based on historical data.

I'll provide a very light introduction to the quadratic optimization method,
which we'll use to select the portfolio. I'll also give a short overview the
script that implements described methods in practice.

The accompanying Python code is available at [my Github repo][githubrepo]. The
`README.md` file explains how to run the analysis.

Please be aware that I am not giving financial advice. Using methods presented
in this post may give poor results in practice.

## Quadratic optimization

### Maximize the gain

The very first task in analytic thinking is formal problem definition;
definition of what we want. In the problem, we have a collection of
securities - $$S_1$$, $$S_2$$, ..., $$S_n$$. We'd like to find a combination of
securities that maximizes the return after, for example, a few years. We'll use
vector $$a = [a_1, \ldots, a_n], \sum_{k=1}^N a_k$$ to denote a solution.

We don't know the future, so we, like in statistics, have to make some
assumptions. For example, prices tend to follow their historical behavior. This
assumption seems to make sense and is also easy to translate into results as
price history is usually available on the Internet.

Then, a straightforward answer to our question is to choose a portfolio that
would have maximized the return in a given time period in the past. Given
historical returns $$r = [r_1, \ldots, r_n]$$, find
$$a = [a_1, \ldots, a_n], \sum a_i = 1$$
that maximizes $$a \cdot r = \sum_{i=1}^n a_i r_i$$.

It is a simple method. So simple that it only chooses an elementary vector
$$e_j$$ with $$j$$ being the index of the largest $$r_j$$. This drawback of this
method stem from not taking risk, i.e. price volatility, into account. We'll
have to introduce that concept into our model.

### Risk

We'll use variance as our measure of volatility. Given a history of monthly
price changes, $$h_j = [h_1, \ldots, h_m]$$ of security $$S_j$$ over the last
$$m$$ months, we calculate its variance as
$$\mathbb{V}\left(h_j\right) = \mathbb{E} \left(h_k - \mathbb{E}(h_k)\right)^2$$.
The bigger this value, the more volatile the price history.

I'd like to introduce one more tool before we formulate how we want to include
risk into our model - covariance. Covariance can be used to measure how two
variables, like security prices, depend on each other. The formula is

$$\mathtt{Covar}\,(h_j, h_k) = \mathbb{E}(h_j^2) \mathbb{E}\left(h_k^2\right) -\left(\mathbb{E}\left(h_j\right) \mathbb{E}\left(h_k\right)\right)^2$$

Going back to the model, we'll elaborate the "maximize expected return" task
into "maximize expected return, given that risk is at constant level v".
In more mathematical notation, we'd like to find
$$\mathtt{argmax}_a a \cdot r$$
such that $$\mathbb{V}(a \cdot h) = v$$, where $$v$$ is constant. One thing
worth knowing is that we can express portfolios's variance as a linear
combination of variances and covariances of individual securities:

$$
\mathbb{V}(a \cdot h) = \sum_{j=1}^n a_j^2 \mathbb{V}(h_j) + \sum_{j=1}^n\sum_{k=1}^n a_ja_k \mathtt{Covar}(h_j, h_k)
$$

We can express this in even more succint form. Let $$P = [p_{i, j}]$$ be a
$$n \times n$$ matrix such that $$p_{i, j} = \mathtt{Covar}(h_j, h_k)$$. Such
matrix is called a *covariance matrix*. Then

$$
\mathbb{V}(a \cdot h) = a P a^T
$$

### Quadratic optimization

We're done with defining the model of our problem. Now we can turn our heads
toward finding a way to solve it. Luckily for us, our problem belongs to a class
of problems known as convex optimization problems. They occur quite often in the
real world, and efficient solving methods are known and widely available.
Formally, the problem of maximizing

$$xR - xPx^{T}$$

with respect to $$x$$ is known as [*quadratic optimization*][quadoptwiki]. The
code in my repository encodes the data into this problem and uses cvxopt, a
Python library, to solve it.

Why is this class of problems called convex optimization problems? It's because
curves defined by that kind of equation are convex. For example, for
2-dimensional $$x$$ we get a paraboloid.

<figure>
<img src="/images/2016/10/paraboloid.svg" alt="Paraboloid" />
</figure>

## Further enhancements

### Choosing risk level

Astute readers may notice that there's no specification of the desired risk
level $$v$$ in the quadratic optimization equation above. That's not a mistake,
and neither it is not desirable. The straightforward application of an
optimization algorithm will some vector $$x$$ such that we know that for risk
level $$xPx^T$$ the expected return, $$xR$$ is maximal. But we didn't choose the
risk level.

The situation can be remedied by introducing a weight variable $$\nu$$, which
will mean how important is the risk factor in the equation. In our program we'll
try out different values of $$\nu$$ and solve

$$xR - \nu \cdot xVx^T$$

We still can't choose the risk-level, but this way we'll generate various
solutions for range of risk-levels from which we can choose the one that we
want.

### Implementing your own strategy

Suppose that we wanted to provide additional restrictions on $$x$$, like - at
least 10% of the portfolio is composed of bond funds. That is possible and quite
easy to do. Quadratic optimization algorithms allow definition of constraints of
the form $$Gx^T \leq h, Ax^T = b$$, where $$G,A$$ are arbitrary matrices and
$$h, b$$ are vectors. For example, to encode a constraint that the second
security gets at least 20% share we would set: $$G = [0, -1, 0, \ldots, 0]$$
and $$h = [-0.2]$$.

## Code

The accompanying code relies on cvxopt library to solve the quadratic equation.
[The library's documentation][cvxoptdoc] provides an excellent and succinct
source of information on the method itself. My script is split into 3 parts.

First, we need to get raw data, clean it, and transform it into a form that is
directly pluggable into the quadratic optimization method. I have used data from
[bossa][bossa] website, which contains daily investment fund prices. The
functions in the script truncate the data to monthly period, get monthly price
changes instead of absolute values etc.

Second, we have get the processed data into an equation and solve it. This is
done in `calculate_sample_portfolios`. The function takes an expected return
matrix $$R$$, a covariance matrix $$P$$, and constraints and outputs optimal
portfolios for a wide range of possible risk levels. Functions
`expected_return`, `covariance`, and `generate_constraints` are used to generate
those arguments.

Third, we have to present the results in a readable fashion.
`plot_risk_vs_return` plots a risk vs return curve of found portfolios.
`plot_stackplot` plots a stackplot that shows the calculated portfolios ordered
by their expected return.

<figure>
<img src="/images/2016/10/stackplot.svg" alt="Portfolio stackplot" />
</figure>

The plots weren't optimized for prettiness, but they are there to provide good
overview of the situation.

## Credits

The whole idea of using this method for portfolio selection came from
[convex optimization book][cvxoptbook].

[githubrepo]: https://github.com/gregorias/qopt-fund-analysis
[quadoptwiki]: https://en.wikipedia.org/wiki/Quadratic_programming
[cvxoptbook]: http://web.stanford.edu/~boyd/cvxbook/bv_cvxbook.pdf
[cvxoptdoc]: http://cvxopt.org/userguide/coneprog.html#quadratic-programming
[bossa]: http://bossa.pl
