# Covid-19, Blame, and Incumbency

October 24, 2020

## Introduction

Covid-19 is obviously at the forfront of many voters minds today. As proven in the final presidential [debate](https://www.wsj.com/articles/final-trump-biden-debate-marks-start-of-sprint-to-election-11603386976), a lot of ambiguity still surrounds the question of different vaccines and the potential end of the pandemic. Also discussed in the debate was President Trump's success or failure with handling the virus, depending on your perspective. This question of "did Trump do a good job with Covid?" draws attention to a larger point of interest: do voters blame Trump for the continued pandemic? 

In this blog post I will investigate this question through looking at the relationship of average poll support for Trump and different measures of Covid-19 progression such as death rate and cases per capita. 

### Background: how did Covid-19 affect different states? 

For some brief context of the historical and current state of Covid-19 in each state, see the visual below that shows Covid-19 cases per 100,000 people in each state. 

![ani](Gov1347-master/figures/case_per_hun.gif)

> - It is apparent that cases per capita is continuing to grow as we near the election
> - Southern states seem to be hit relatively hard on a per capita basis 
> - Battleground states such as Arizona, Georgia, and Florida seem to have some of the highest case rates for their populations

### Is there a relationship between polls and worsening of Covid-19?

If voters do blame Trump for the pandemic, it's possible that it would be reflected in the polls. I would expect that if this were the case, a worsening of Covid-19 conditions would lead to a decrease in support for Trump. The graffic below shows the relationship between shifts in polls and cases per 100,000 across states. As you can see, there doesn't appear to be a relationship between the two variables, and running a regression shows no statistically significant relationship betwen the two variables as well. 

![img](Gov1347-master/figures/poll_change_vs_cases.png)

> - This figure suggests that voters do not punish Trump simply because of an increase in Covid-19 cases
> - It makes sense that the pandemic would not shift the polls in strongly blue or strongly red states, so this could be masking the relationship of poll changes in battleground states
> - However, running a regression that accounts for battleground status does not reveal for any statistically significant relationships either


