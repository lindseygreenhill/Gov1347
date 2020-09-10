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

plot_usmap(data = pv_win_map, regions = "states", values = "winner", color = "white") +
  facet_wrap(facets = year ~.) + ## specify a grid by year
  scale_fill_manual(values = c("blue", "red"), name = "PV winner") +
  labs(title = "Election Results 2008-2018") +
  theme_void() +
  theme(strip.text = element_text(size = 12),
        plot.title = element_text(hjust = .5),
        aspect.ratio=1)
