---
layout: post
title: "My favourite math puzzle - why hope is important"
date:  2014-11-09 16:00
uses_mathjax: true
tags: mathematics puzzle probability
---
Here I will present one of my favourite math puzzles. It holds this rank due to
the seeming impossibility of the task it asks.

> Warden of a prison presented a generous offer to 100 of his prisoners. He will
> place 100 sealed boxes in a room and in each box there will be a paper with a
> number from 1 to 100 written on it (permutation of numbers is chosen
> randomly). Prisoners will consecutively enter the room alone and will be able
> to open up to 50 boxes. If any of those boxes contains his number (prisoners
> will also be numbered from 1 to 100) then he may leave the room, otherwise the
> warden kills everyone. If everyone succeds then they are all released from
> prison. After every prisoner's visit the room is returned to its previous,
> untouched condition. Find a strategy for prisoners which will allow them to
> survive with a chance greater than 30%. Prisoners may discuss the strategy
> they will use before anyone enters, but afterwards any contact is forbidden. 

Solution
--------

This is not a trick puzzle, it's as straightforward as it can get. Before you
read my approach to this problem please try to solve it on your own, you may
find it enlightening. 

<h3>static box alocation</h3>

So why does it seem impossible? First of let's notice that if every prisoner
were to open his boxes randomly then they have $$ \frac{1}{2^{100}} $$ chance of
surviving. That's very bad. Perhaps they might know the order in which they will
enter and might try to decide which boxes everyone will open. The first prisoner
may try to open the first 50 boxes and the second the last 50 boxes since he
knows that in the first 50 boxes there is number one. However after first
two tries we have at most $$ \frac{1}{2} \cdot \frac{50}{99}$$ chance of
surviving. This is less than $$ 30\% $$. No good. We may guess that number 100 is
arbitrary and that if there's any solution than the rules it follows will apply
to any even number of prisoners and then we may try to find a static allocation
that may work for 6 or 8 prisoners. If you have tried this you will notice that
none of them work.

<h3>dynamic box allocation</h3>

After abandoning idea of static allocation, we should look at the alternative.
A prisoner must make the decision which box to open next based on previous
results. Here's a moment of serendipity. Those sealed boxes with numbers in them
work as if they were forming a permutation and the only information we get from
opening is one number of permutation. What can we do with that number? Not much
really, the only obvious choice that comes to mind is to go to the box with the
number we chose. So here's an idea for a strategy:

> Each prisoner upon entering the room will open a box corresponding to his
> number. If he does not find his own number then he goes to the box pointed by
> the box chosen. This action is repeated until he finds his own number.

If we return to our permutation analogy we can see that this strategy will
guarantee success if and only if the permutation does not contain a cycle longer
than 50.

I came back to the conclusion that this is the only sane strategy while riding a
bus so I only checked it for permutations of 4 and it seemed remarkably good.
After I came back home I wrote up a script to calculate the chance for bigger
number of prisoners.

{% highlight python %}
#!/usr/bin/env python3
import itertools
import math

def calc_longest_cycle_length(permutation):
  visited = [False] * len(permutation)
  longest_cycle_length = 0

  for i in range(len(permutation)):
    if not visited[i]:
      cycle_length = 1
      j = permutation[i]
      visited[i] = True
      while j != i:
        cycle_length += 1
        j = permutation[j]
        visited[j] = True
      longest_cycle_length = max(longest_cycle_length, cycle_length)

  return longest_cycle_length

def calc_chance_of_survival_with_cycle_strategy(n):
  perms = itertools.permutations(range(n))
  longest_cycle_lengths = (calc_longest_cycle_length(perm) for perm in perms)
  survival_perms_count = len([length for length in longest_cycle_lengths if
    length <= n/2])
  return float(survival_perms_count)/float(math.factorial(n))

if __name__ == '__main__':
  n = int(input("Provide number of prisoners: "))
  print("The chance of prisoners survival is: ", end="")
  print(calc_chance_of_survival_with_cycle_strategy(n))
{% endhighlight %}
 
For 10 prisoners we get $$ 35.44\% $$ chance of survival compared to around
$$0.1\%$$ for random strategy. It seems like we got it. Time for formal proof.

<h3>Mathematical proof</h3>

As we have noticed before, our strategy works iff there is no cycle larger than
$$ \frac{n}{2} $$ for $$n$$ prisoners. Let's calculate the chance of finding
such a larger cycle in random permutation. The number of permutations of size
$$n$$ containing cycle of size $$ m $$, where $$ m > \frac{n}{2}$$ is equal to
the product of 3 things: number of ways we can choose numbers in the large cycle
($$ {n \choose m} $$), number of different permutations numbers inside the
large cycle can be ($$ (m-1)! $$, not $$m!$$, because it's a cycle) and number
of different permutations all numbers outside a cycle can form ($$ (n-m)!$$). So
in the end we get the product:

$$ {n \choose m} (m-1)! (n-m)! = \frac{n!}{m} $$

So the chance of survival is $$ 1 $$ minus the chance of finding large cycle of
size larger than $$ \frac{n}{2} $$ that is:

$$ 1 - \frac{\sum_{m = \left(\frac{n}{2} + 1\right)}^n \frac{n!}{m}}{n!} =
1 - \sum_{m = \left(\frac{n}{2} + 1\right)}^n \frac{1}{m}  $$

For $$ n = 10 $$ we can calculate:

$$ 1 - \sum_{m = 6}^{10} \frac{1}{m} \approx 0.3543  $$

Exactly as in our program. How does it behave for large $$ n $$? Let's notice
that our formula is just: $$ 1 - \left(H_n - H_{\frac{n}{2}}\right) $$ where $$ H_n $$ is n'th
harmonic number. Therefore:

$$ 1 - \left(H_n - H_{\frac{n}{2}}\right) \approx 1 - \left(\log n - \log \frac{n}{2}\right) =
1 - \log 2 = 0.307 $$

How good is this approximation? Very good, since the maximum error value of $$H_n
\approx \log n$$ is bounded by Euler-Mascheroni constant therefore error in our
approximation decreases to zero as n grows to infinity. Also the sequence is
decreasing. Therefore $$0.307$$ is the lower bound for the chance of success of
our strategy.

That was neat, wasn't it? We found the solution, not because we have labourously
surveyed all combinations or used a nontrivial mathematical theorem, but because
it was the only sane choice given very limited information that prisoners have
and we were given hope that solution exists. The proof that it works required
some mathematical proficiency, but is still short and elegant. That's why this
is my favourite puzzle.

Dishonest warden
----------------

Everybody knows the well-known trope that wardens are evil sadists. Why should
the puzzle warden be any different?

<h3>The permutation is not uniformly random</h3>

The warden might have read this blog and decided to put numbers in such a way
that they form one big cycle. For example by putting number 2 to first box,
number 3 to second box etc. Are the prisoners doomed?

In cryptography one might learn that if we have a random variable representing a
binary string which may not necessarily be uniformly random than xoring it with
a uniformly random variable will give us uniformly variable binary string. In
fact this is the idea behind one time pad. Prisoners here may do the same thing.
Instead of relying solely on the permuation given by the warden they will
generate their own permutation as well and apply it to the boxes numbers,
provided the warden does not know what permutation they use and that it is
uniformly random. Here is more formal proof. Let $$\Phi$$ be the random variable
for permutation chosen by the warden, we do not know its distribution. Let
  $$\Theta$$ be the uniformly random variable for the permutation chosen by the
  prisoners independent from $$\Phi$$. Let $$ S(n) $$ be the set of permutation
  of numbers from 1 to n and $$ \sigma \in S(n)$$

$$
\begin{align*}
\mathbb{P}\left( \Phi \circ \Theta = \sigma\right)
&=&
\sum_{\phi \in S(n)} \mathbb{P}\left(\Phi = \phi, \Theta = \phi^{-1}\sigma \right) \\
&=&
\sum_{\phi \in S(n)} \mathbb{P}\left(\Phi = \phi\right)\mathbb{P} \left(\Theta = \phi^{-1}\sigma \right) \\
&=&
\sum_{\phi \in S(n)} \mathbb{P}\left(\Phi = \phi\right) \frac{1}{|S(n)|}\\
&=&
\frac{1}{|S(n)|}\\
\end{align*}
$$

So after prisoners apply their own permutation then every permutation is equally
probable, since $$\sigma$$ is an arbitrary permutation, denying any possible
tampering by the warden.

<h3>The permutation changes after every visit</h3>

What if the warden keeps the permutations fair, but decides that he will change
the order of numbers after every visit? Then the prisoners are doomed with our
strategy. Firstly let's notice that both our previous proofs rely on the fact
that permutation was chosen once and either there is a large cycle or isn't. If
however the warden chooses a different permutation each time then the prisoner
dies iff the permutation has large cycle and his number is in that cycle. The
chance for that is at least $$ \frac{7}{10} \times \frac{1}{2} \approx 35 \% $$,
so every prisoner has at least $$35\%$$ chance of failing. Needless to say the
chance of all 100 prisoners surviving is abysmal.

Can we do better?
-----------------

For the end we might ask whether our strategy is optimal? Perhaps if the
prisoners based their decision on their entire history, instead of just the last
number, they might get a better result. But I'll leave this question for a
future post, if I'll return to it at all.
