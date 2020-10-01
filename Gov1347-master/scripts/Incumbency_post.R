#### Incumbency ####
#### Gov 1347: Election Analysis (2020)
#### Lindsey Greenhill

# installing packages

library(tidyverse)
library(ggplot2)
library(usmap)
library(janitor)
library(readxl)
library(RColorBrewer)
options(scipen=999)

# reading in data

covid <- read_excel("Gov1347-master/data/GridExport_09_030_2020.xlsx") %>%
  clean_names() %>%
  select(state, total)

state_pop <- read_csv("Gov1347-master/data/state_pop.csv") %>%
  clean_names() %>%
  select("state" = name, "pop" = popestimate2019)

# merging state pop and covid data and creating an aid per capita

covid_pop <- state_pop %>%
  inner_join(covid, by = "state") %>%
  mutate(aid_per_cap = total/pop)

# creating map of total and per cap

states_map <- usmap::us_map()
  
  
map_total <- plot_usmap(
  data = covid_pop,
  regions = "states",
  values = "total",
  color = "black"
) +
  scale_fill_gradient(high = "darkblue",
                      low = "aliceblue",
                      name = "Total Award (USD)") +
  labs(title = "State Covid-19 Award Totals") +
  theme_void() +
  theme(
    strip.text = element_text(size = 12),
    plot.title = element_text(size = 18, hjust = .5),
    aspect.ratio = 1
  )

map_per_cap <- plot_usmap(
  data = covid_pop,
  regions = "states",
  values = "aid_per_cap",
  color = "black"
) +
  scale_fill_gradient(high = "darkblue",
                      low = "aliceblue",
                      name = "Total Award (USD)") +
  labs(title = "State Covid-19 Awards ($ per capita)") +
  theme_void() +
  theme(
    strip.text = element_text(size = 12),
    plot.title = element_text(size = 18, hjust = .5),
    aspect.ratio = 1
  )


  


