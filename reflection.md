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
> - These results translate into my model being abouot 94% accurate

*Note:* My model did not account for the different electoral vote districts in Nebraska and Maine, which both ended up voting for the opposite party from the rest of the state. Maine's electoral district voted republican and Nebraska's voted democrat. If I redid my model, I would account for these districts. 

### A closer look

My model correctly predicted 48 out of 51 states (including DC), but how close were my point predictions to the actual vote share? The graphic below shows my the actual Biden vote margins vs. my predicted Biden vote margins. If a state is on the dotted blue line, then my predicted vote margin lines up exactly with the wactual vote margin.  If a state is below the dotted blue line, then the actual Biden vote margin was less than I predicted it to be. For example, in Idaho, I predicted Biden's vote margin to be -18.7%, but the actual Biden vote margin was -30.7%.

![errors](Gov1347-master/figures/reflection_margin_errors.png)

##### Discussion

> - In general, I tended to overestimate Biden and underestimate Trump
> - In states where I predicted Trump would win (those in the bottom left quadrant), I for the most part underestimated Trump's win margin
> - In states where I predicted Biden would win (those in the top right quadrant), I for the most part overestimated his Biden's win margin
> - The states that I predicted Biden would win but didn't are in the bottom right quadrant (Florida, North Carolina, and Iowa)

The graphic below visualizes these errors in another way. 

![errors_2](Gov1347-master/figures/reflection_margin_errors_bar.png)

##### Discussion

> - My model performed the worst in New York, where I predicted Biden would win with a 30.8% margin. As of the last time I checked, Biden only by 12.7 points. However, not all of the votes had been counted so that margin could change.
> - The only states I overestimated Biden's vote margin are Louisiana, Maryland, and Illinois.
> - My model was very close in Illinois, Hawaii, Geogia, Vermont, California, and Colorado. 
> - As I discussed above, the takeaway from these errors is that I underestimated Trump in most states. 

### Some statistics

Overall given the data above, my model had a RMSE of **6.7**. It performed slightly better in battleground states (AZ, GE, OH, FL, NH, NV, MI, PA, MN, WI, NC, IA, TX) than non battleground states. For reference, the RMSE of Nate Silver's 538 model was 

![tab](Gov1347-master/figures/reflection_RMSE.png)

### Where did it go wrong?

There are a few places where my model could've gone wrong. For one, my model relied heavily on **polling data**, and, as with 2016, the polls for 2020 were not particularly accurate. Secondly, my model also relied on demographic data, and I 

#### What went wrong in the polls?

There are a few theories as to what was wrong with the polls. 
 > - Most believe that the education distribution problem from 2016 were corrected for 2020
 > - 
