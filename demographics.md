# Do Demographic Changes Affect Election Results?

October 17, 2020

### Introduction

This week's blog post will focus on the inclusion of demographics into my predictive model. I will also discuss the usage of a new pooled 
model that includes data from every state as opposed to usage of state models that include data only from a particular state. 

### Incorporating Demographics into my Model

There are many reasons why demographics could be important in predicting elections. Certain demographic groups, such as Hispanics, Women, Asians,
and a few others predicably vote democrat. Other demographic groups, such as Whites, more often vote republican. As such, a change in the proportions 
of demographic groups in an electorate can have an impact on election results. If we know the historical effect of each of these groups on election
outcomes, we can predict how the demographic changes in 2020 could influence the election. 

Unfortunately, I only have access to historical democratic demographics data and not historical republican demographic data. Therefore, I could
only build a demographics model for the democrat vote share and had to rely on a polling model for the republican vote share. 

The table below shows the results of three different pooled models. 

![tab](Gov1347-master/figures/star_test.png)

##### Analysis
