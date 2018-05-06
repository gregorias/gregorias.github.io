---
layout: post
title:  "Who would survive the Titanic?"
date: 2018-05-06
---


<figure>
<img src="/images/2018/1280px-RMS_Titanic_3.jpg" alt="Titanic" />
</figure>

There's [a practice exercise on Kaggle][titanic-kaggle] that gives Titanic
passenger data and asks us to find the best predictor of survival.
The exercise seems exciting, so, in this post, I will dive into Titanic data.

I will first present relationships between passengers' attributes and their
survival rate. Then, I'll attempt to create a model for predicting survival.
We'll see what information matters and what doesn't.

## Data available

Kaggle gives data on a random sample of 2344 passengers: their class, age,
family relationships, lodging, and general trip information.

<figure>
<img src="/images/2018/Screenshot-2018-4-24%20A%20foray%20into%20Titanic%20data.png"
     alt="A screenshot showing a sample of input data." />
<figcaption>Input data</figcaption>
</figure>

The general survival rate &ndash; the most important metric &ndash; rate was
38.4%.

<figure>
<img src="/images/2018/surv_death_rate.png"
     alt="Pie chart showing the survival and death rates"
     style="width: 50%"/>
<figcaption>Survival and death rates</figcaption>
</figure>


## Age, Gender, Wealth &ndash; basic correlations

Let's see how important each attribute is on its own.
### Age

<figure>
<img src="/images/2018/age_surv.png"
     alt="Distribution of ages among survivors and victims" />
<figcaption>Distribution of ages among survivors and victims</figcaption>
</figure>

Note that around 20% of entries did not have the age attribute.

### Gender

<figure>
<img src="/images/2018/sex_surv.png"
     alt="Gender distribution among survivors and victims" />
<figcaption>Survival rate with respect to gender</figcaption>
</figure>

### Wealth

<figure>
<img src="/images/2018/class_surv.png"
     alt="Class distribution among survivors and victims" />
<figcaption>Survival rate with respect to class</figcaption>
</figure>

### Lodging

There were 8 main decks on Titanic: from A to G, and auxiliary decks like Tank
deck.

<figure>
<img src="/images/2018/deck_surv.png"
     alt="Distribution of ages among survivors and victims" />
<figcaption>Survival rate with respect to the cabin's deck</figcaption>
</figure>

Only 22.9% of passengers have cabin data in the sample, which explains why this
attribute is highly biased.

### Feature importance

There are other meaningful features, but we covered the most interesting ones.
Here's a comparison of relative feature importances as measured using [relative
Gini importance][rf_importance].

<figure>
<img src="/images/2018/feat_imp.png"
     alt="Feature importance" />
<figcaption>Feature importance</figcaption>
</figure>

## Classification

I've tried using decision tree-based models as predictors. Note, that the base
survival rate was 38%; even a classifier that always gives "Death" verdict would
have 62% accuracy.

From the initial survey, it looks the gender is the best indicator of survival,
and, indeed, a tree that just splits based on gender has 79% of estimated
accuracy.

<figure>
<img src="/images/2018/age_tree.png"
     alt="A decision tree based on gender." />
<figcaption>A decision tree based on gender</figcaption>
</figure>

Putting all data that is available in the input set doesn't increase the
estimate by much: only up to 82%. Here's one of the best decision trees that I
have trained:

<figure>
<img src="/images/2018/full_tree.png"
     alt="A decision tree" />
<figcaption>One of the best decision trees.</figcaption>
</figure>

The tree would predict that men with a cabin number and that are less than 36
years old would survive. According to the model, Women in the third class who
embarked from Southampton would die.

I've also tried using more complicated models. A gradient boosted decision tree
would get even 85% accuracy when measured using
[cross-validation][cross-validation].

<figure>
<img src="/images/2018/tree_accs.png"
     alt="Comparison of CV accuracy of all models." />
<figcaption>Comparison of CV accuracy of all models</figcaption>
</figure>

## Verification with test data

I submitted results from all four models, and a surprising thing happened. The
gradient boosted model performed worse than the gender-based tree. The likely
explanation here is that I've been creating overfitted models.

<figure>
<img src="/images/2018/test_accs.png"
     alt="Comparison of test accuracy of all models." />
<figcaption>Comparison of test accuracy of all models</figcaption>
</figure>

## Source

The Jupyter notebook I used for this analysis is available on
[Kaggle][notebook].

[titanic-kaggle]: https://www.kaggle.com/c/titanic/kernels?sortBy=date&group=upvoted&pageSize=20&competitionId=3136
[cross-validation]: https://en.wikipedia.org/wiki/Cross-validation_(statistics)
[rf_importance]: http://scikit-learn.org/stable/auto_examples/ensemble/plot_forest_importances.html
[notebook]: https://www.kaggle.com/gregorias/titanic-data-analysis
