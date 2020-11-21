# Post Election Model Reflection

November 23, 2020
Lindsey Greenhill

#### Introduction

Joe Biden won the 2020 election with 306 electoral votes. Donald Trump lost with 232. This blog post will look at how well [my model](final_prediction.md) predicted these results. Spoiler alert: it left something to be desired. 

### What happened on a state by state basis?

My model predicted that Biden would win with 356 electoral votes. So, where was I wrong? The map belows shows a comparison of my final predictions with what actually happened. 

![maps](Gov1347-master/figures/reflection_results_map.png)

##### Discussion

> - My model incorrectly predicted 3 states (Florida, North Carolina, and Iowa)
> - All of these states went to Trump
> - These states' 50 electoral votes (FL 29, NC 15, IA 6) make up the difference between the actual electoral vote count and my predicted vote count 

*Note:* My model did not account for the different electoral vote districts in Nebraska and Maine, which both ended up voting for the opposite party from the rest of the state. Maine's electoral district voted republican and Nebraska's voted democrat. If I were to redo my model, I would account for these districts. 

### A closer look
