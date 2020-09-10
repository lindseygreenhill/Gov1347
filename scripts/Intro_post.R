#### Introduction ####
#### Gov 1347: Election Analysis (2020)
#### Lindsey Greenhill

# installing packages

library(tidyverse)
library(ggplot2)
library(usmap)

# setting workind directory

setwd("/Users/lindseygreenhill/Desktop/Elections/Gov1347")

# reading in voting data

popvote_df <- read_csv("data/popvote_1948-2016.csv")
## reading in state data
pvstate_df <- read_csv("data/popvote_bystate_1948-2016.csv")
pvstate_df$full <- pvstate_df$state

# creating  maps of last three elections with labels

# shapefile of states from `usmap` library
# note: `usmap` merges this internally, but other packages may not!

states_map <- usmap::us_map()
unique(states_map$abbr)

# this code taken from section

pv_win_map <- pvstate_df %>%
  filter(year >=2008) %>%
  mutate(winner = ifelse(R > D, "Republican", "Democrat"))

# faceting by year to create grid. Adding title and centering title

plot_usmap(
  data = pv_win_map,
  regions = "states",
  values = "winner",
  color = "white"
) +
  facet_wrap(facets = year ~ .) + ## specify a grid by year
  scale_fill_manual(values = c("blue", "red"), name = "PV winner") +
  labs(title = "Election Results 2008-2018") +
  theme_void() +
  theme(
    strip.text = element_text(size = 12),
    plot.title = element_text(hjust = .5),
    aspect.ratio = 1
  )

# saving grid as an image

ggsave("figures/PV_states_grid.png", height = 3, width = 8)

# creating model to predict election. Including last three election cycles 
# because that was the last time a republican was incumbent

# creating a forcasts data frame to store forcasts

forcasts <- data.frame()

# looping through states to add information to forcasts

for(state in unique(pvstate_df$state)){
  state <- state
  
  # calculating the democratic  vote percentage
  
  D_pred_2020 <-
    pvstate_df$D_pv2p[pvstate_df$state == state &
                        pvstate_df$year == 2016] * .7 +
    pvstate_df$D_pv2p[pvstate_df$state == state &
                        pvstate_df$year == 2012] * .2 +
    pvstate_df$D_pv2p[pvstate_df$state == state &
                        pvstate_df$year == 2008] * .1
  
  # calculating the republican vote percentage
  
  R_pred_2020 <-
    pvstate_df$R_pv2p[pvstate_df$state == state &
                        pvstate_df$year == 2016] * .7 +
    pvstate_df$R_pv2p[pvstate_df$state == state &
                        pvstate_df$year == 2012] * .2 +
    pvstate_df$R_pv2p[pvstate_df$state == state &
                        pvstate_df$year == 2008] * .1
  
  # creating a vector to use in bind rows  
  
  vector <-
    data.frame(state = state,
               D_pv2p = D_pred_2020,
               R_pv2p = R_pred_2020)
  
  # binding vector with forcasts
  
  forcasts <- forcasts %>% bind_rows(vector)
}

 forcasts <- forcasts %>% mutate(year = 2020, margins = R_pv2p - D_pv2p)
 
 # mutating to create a win column in forcasts 
 
 forcasts_wins <-
   forcasts %>% mutate(winner = if_else(D_pv2p > R_pv2p, "democrat", "republican"))
 
 # plotting map using blue and red
 
 plot_usmap(
   data = forcasts_wins,
   regions = "states",
   values = "winner",
   color = "white"
 ) +
   scale_fill_manual(values = c("blue", "red"), name = "PV winner") +
   labs(title = "Predicted Election Results 2020") +
   theme_void() +
   theme(
     strip.text = element_text(size = 12),
     plot.title = element_text(hjust = .5),
     aspect.ratio = 1
   )
 
 ggsave("figures/2020_blue_red.png", height = 4, width = 5)
 


