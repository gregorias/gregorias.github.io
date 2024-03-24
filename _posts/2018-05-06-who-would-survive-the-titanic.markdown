---
layout: post
title:  "Who would survive the Titanic?"
date: 2018-05-06
---

![Titanic](/images/2018/1280px-RMS_Titanic_3.jpg)

There's [a practice exercise on Kaggle][titanic-kaggle] that gives Titanic
passenger data and asks us to find the best predictor of survival.
The exercise seems exciting, so, in this post, I will dive into Titanic data.

I will first present relationships between passengers' attributes and their
survival rate. Then, I'll attempt to create a model for predicting survival.
We'll see what information matters and what doesn't.

## Data available

Kaggle gives data on a random sample of 2344 passengers: their class, age,
family relationships, lodging, and general trip information.

![A screenshot showing a sample of input data.](/images/2018/Screenshot-2018-4-24%20A%20foray%20into%20Titanic%20data.png)
_Input data_

The general survival rate &ndash; the most important metric &ndash; rate was
38.4%.

![Pie chart showing the survival and death rates](/images/2018/surv_death_rate.png)
_Survival and death rates_

## Age, Gender, Wealth &ndash; basic correlations

Let's see how important each attribute is on its own.

### Age

![Distribution of ages among survivors and victims](/images/2018/age_surv.png)
_Distribution of ages among survivors and victims_

Note that around 20% of entries did not have the age attribute.

### Gender

![Gender distribution among survivors and victims](/images/2018/sex_surv.png)
_Survival rate with respect to gender_

### Wealth

![Class distribution among survivors and victims](/images/2018/class_surv.png)
_Survival rate with respect to class_

### Lodging

There were 8 main decks on Titanic: from A to G, and auxiliary decks like Tank
deck.

![Distribution of ages among survivors and victims](/images/2018/deck_surv.png)
_Survival rate with respect to the cabin's deck_

Only 22.9% of passengers have cabin data in the sample, which explains why this
attribute is highly biased.

### Feature importance

There are other meaningful features, but we covered the most interesting ones.
Here's a comparison of relative feature importances as measured using [relative
Gini importance][rf_importance].

![Feature importance](/images/2018/feat_imp.png)
_Feature importance_

## Classification

I've tried using decision tree-based models as predictors. Note, that the base
survival rate was 38%; even a classifier that always gives "Death" verdict would
have 62% accuracy.

From the initial survey, it looks the gender is the best indicator of survival,
and, indeed, a tree that just splits based on gender has 79% of estimated
accuracy.

![A decision tree based on gender.](/images/2018/age_tree.png)
_A decision tree based on gender_

Putting all data that is available in the input set doesn't increase the
estimate by much: only up to 82%. Here's one of the best decision trees that I
have trained:

![A decision tree](/images/2018/full_tree.png)
_One of the best decision trees._

The tree would predict that men with a cabin number and that are less than 36
years old would survive. According to the model, Women in the third class who
embarked from Southampton would die.

I've also tried using more complicated models. A gradient boosted decision tree
would get even 85% accuracy when measured using
[cross-validation][cross-validation].

![Comparison of CV accuracy of all models.](/images/2018/tree_accs.png)
_Comparison of CV accuracy of all models_

## Verification with test data

I submitted results from all four models, and a surprising thing happened. The
gradient boosted model performed worse than the gender-based tree. The likely
explanation here is that I've been creating overfitted models.

![Comparison of test accuracy of all models.](/images/2018/test_accs.png)
_Comparison of test accuracy of all models_

## Source

The Jupyter notebook I used for this analysis is available on
[Kaggle][notebook].

[titanic-kaggle]: https://www.kaggle.com/c/titanic/kernels?sortBy=date&group=upvoted&pageSize=20&competitionId=3136
[cross-validation]: https://en.wikipedia.org/wiki/Cross-validation_(statistics)
[rf_importance]: http://scikit-learn.org/stable/auto_examples/ensemble/plot_forest_importances.html
[notebook]: https://www.kaggle.com/gregorias/titanic-data-analysis
