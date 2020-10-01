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
library(ggpubr)
options(scipen=999)

# reading in data

covid <- read_excel("Gov1347-master/data/GridExport_09_030_2020.xlsx") %>%
  clean_names() %>%
  select(state, total)

state_pop <- read_csv("Gov1347-master/data/state_pop.csv") %>%
  clean_names() %>%
  select("state" = name, "pop" = popestimate2019)

covid_per_state <- read_csv("Gov1347-master/data/united_states_covid19_cases_and_deaths_by_state.csv",
                            skip = 3) %>%
  clean_names() %>%
  select("state" = state_territory, total_cases)

# getting list of competitive states

popvote_bystate <-  read_csv("Gov1347-master/data/popvote_bystate_1948-2016.csv") %>%
  select(state, year, R_pv2p, D_pv2p) %>%
  filter(year %in% c(2008, 2012, 2016)) %>%
  mutate(loser_pv = if_else(R_pv2p > D_pv2p, D_pv2p, R_pv2p)) %>%
  group_by(state) %>%
  summarise(avg_loser = mean(loser_pv)) %>%
  filter(avg_loser >= 45)
# 15 competitive states: Arizona, Colorado, Florida, Georgia, Iowa, Michigan,
# Minnesota, Missouri, Nevada, New Hampshire, North Carolina, Ohio,
# Pennsylvania, Virginia, Wisconsin

# merging state pop and covid data and creating an aid per capita

covid_pop <- state_pop %>%
  inner_join(covid, by = "state") %>%
  mutate(aid_per_cap = total/pop) %>%
  left_join(covid_per_state, by = "state") %>%
  mutate(aid_per_case = total / total_cases)

# creating map of total and per cap and per case

states_map <- usmap::us_map()
  
  
map_total <- plot_usmap(
  data = covid_pop,
  regions = "states",
  values = "total",
  color = "black"
) +
  scale_fill_gradient(high = "darkblue",
                      low = "aliceblue",
                      name = "Total Aid (USD)") +
  labs(title = "State Covid-19 Aid Totals") +
  theme_void() +
  theme(
    strip.text = element_text(size = 12),
    plot.title = element_text(size = 18, hjust = .5),
    aspect.ratio = 1
  )

# creating map for per cap awards

# map_per_cap <- plot_usmap(
#   data = covid_pop,
#   regions = "states",
#   values = "aid_per_cap",
#   color = "black"
# ) +
#   scale_fill_gradient(high = "darkblue",
#                       low = "aliceblue",
#                       name = "Aid per Capita (USD)") +
#   labs(title = "State Covid-19 Aid ($ per capita)") +
#   theme_void() +
#   theme(
#     strip.text = element_text(size = 12),
#     plot.title = element_text(size = 18, hjust = .5),
#     aspect.ratio = 1
#   )
map_per_case <- plot_usmap(
  data = covid_pop,
  regions = "states",
  values = "aid_per_case",
  color = "black"
) +
  scale_fill_gradient(high = "darkblue",
                      low = "aliceblue",
                      name = "Aid per Case (USD)") +
  labs(title = "State Covid-19 Aid ($ per case)") +
  theme_void() +
  theme(
    strip.text = element_text(size = 12),
    plot.title = element_text(size = 18, hjust = .5),
    aspect.ratio = 1
  )


# arranging and saving the maps

ggarrange(map_total ,map_per_case,
          align = "hv",
          nrow = 1)
ggsave("Gov1347-master/figures/covid_award_maps.png")

# creating data sets for non comp and comp states

comp_states <- covid_pop %>%
  mutate(status = if_else(state %in% popvote_bystate$state, "competitive",
                          "not competitive"))

# boxplot of competitive and non competitive states


ggplot(comp_states, aes(y = aid_per_case, x = status, fill = status)) +
  geom_boxplot() +
  scale_fill_brewer(palette = "BuPu") +
  theme_classic() +
  scale_x_discrete(labels = c("Competitive", "Not Competitive")) +
  labs(x = "",
       y = "Aid per Case") +
  labs(title = "Aid per Case Competitive vs. Non Competitive States",
       subtitle = "More competitive states have not received more aid") +
  theme(legend.position = "none",
        plot.title = element_text(size = 20),
        plot.subtitle = element_text(size=18),
        axis.title = element_text(size=16),
        axis.text = element_text(size=13))

ggsave("Gov1347-master/figures/state_award_box.png")

# creating a barchart of aid in swing states swing states decided by
# https://www.politico.com/news/2020/09/08/swing-states-2020-presidential-election-409000

swing_states <- covid_pop  %>%
  filter(state %in% c("Arizona", "Florida", "Georgia", "Michigan",
                  "Minnesota", "North Carolina", "Pennsylvania", "Wisconsin"))
mean_aid <- mean(covid_pop$aid_per_case)
mean_total <- mean(covid_pop$total)

ggplot(swing_states, aes(x = state, y = aid_per_case)) +
  geom_col(fill = "lightblue") +
  geom_hline(yintercept = mean_aid) +
  theme_classic() +
  labs(title = "Avg Aid per Case for 8 Swing States",
       subtitle = "National Average = 7624.5",
       x = "",
       y = "Average Aid per Case") +
  theme(plot.title = element_text(size = 20),
        plot.subtitle = element_text(size=18),
        axis.title = element_text(size=16),
        axis.text.x = element_text(size=13, angle = 45, vjust = .5),
        axis.text.y = element_text(size=13))

ggsave("Gov1347-master/figures/swing_aid_percap.png")

ggplot(swing_states, aes(x = state, y = total)) +
  geom_col() +
  geom_hline(yintercept = mean_total)


## incorporating this model as pv = a(avg_support) + b(aid_per_cap)




  


