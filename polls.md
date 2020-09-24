# Using Polls to Predict Elections

### Introduction

Switching gears from last week's blog post on the [economy](Econ.md), this week's
blog post focuses on the predictive power of polls. First, I will show and evaluate a model
that focuses on nation-level polls. Then, I will compare that model to models built
on a state-by-state basis. Finally, I will use these models to predict the 2020 election

### Model 1: National Level Polls

Although I call this section model 1, it really discusses two models: one for incumbent vote share
and one for challenger vote share. For each model, I ran a linear regression of
popular vote share vs. average poll support. The independent variable, average poll support,
was calculated by taking the average result from each poll six weeks out from the election
in every year (i.e. the average support in 2008 would be equal to the average result of every poll from 2008
taken about six weeks out from the election in the data set). I only include polls taken six weeks
out from the election because, as of today (9/23/2020), we are about six weeks away from the 2020
election. Moreover, polls become [increasingly better predictors](https://www.semanticscholar.org/paper/Election-forecasting%3A-Too-far-out-Jennings-Lewis-Beck/7d0621cd3f984483652caf09e7764c88233948d7) of the election as they get
closer to the election, so it makes sense to focus on the most recent data we have available (as of today, that is polls
about six weeks away from the election). 



for the incumbent or challenger depending o

This first model is built using national-level poll data from 1980 onwards.


I ran 
linear regressions on vote share vs average poll support for both the incumbent vote
share and the challenger vote share








Before diving into building predictive models,
it is important context to first discuss some of the pros and cons of using polls as a statistical tool to 
see why they would be useful in predicting an election.

Pros: One major pro of polling 
An important pro of 



Of course, there are pros and cons 
of polling as a statistical tool However, 


Although polling is sometimes critisized
as 

Whether or not you still trust polls after
the [2016 election](https://www.pewresearch.org/fact-tank/2016/11/09/why-2016-election-polls-missed-their-mark/),
there is no denying 
