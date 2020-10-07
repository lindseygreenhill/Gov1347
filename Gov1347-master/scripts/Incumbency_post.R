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

competitive <- popvote_bystate$state
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


## incorporating this model as pv = a(avg_support) + b(aid_per_cap)*competitive_state

## Updated 2020 presidential forecast incorporating polling data

library(tidyverse)
library(ggplot2)
library(webshot)
library(kableExtra)
library(gt)

#####------------------------------------------------------#
##### Read and merge data ####
#####------------------------------------------------------#

popvote_df <- read_csv("Gov1347-master/data/popvote_1948-2016.csv")
economy_df <- read_csv("Gov1347-master/data/econ.csv")
poll_df    <- read_csv("Gov1347-master/data/pollavg_1968-2016.csv")

# reading in electoral college data

vector <- data.frame(state = "District of Columbia", votes = 3)
EC <- read_csv("Gov1347-master/data/electoral_college.csv") %>%
  select(state = State, votes = electoralVotesNumber) %>%
  bind_rows(vector)


#####------------------------------------------------------#
#####  Proposed models ####
#####------------------------------------------------------#
library(ggplot2)
library(ggrepel)
library(ggpubr)





#####------------------------------------------------------#
#####  State extension####
#####------------------------------------------------------#

# making popvote smaller
pv_df  <- popvote_df %>%
  select(year, party,incumbent_party)

# reading in state data

state_avg <- read_csv("Gov1347-master/data/pollavg_bystate_1968-2016.csv")
state_pv <- read_csv("Gov1347-master/data/popvote_bystate_1948-2016.csv") %>%
  mutate(republican = (R / total) * 100, democrat = (D/total) * 100) %>%
  pivot_longer(cols = c("republican", "democrat"), names_to = "party",
               values_to = "pv") %>%
  select(year,state, party, pv) %>%
  filter(year >= 1972) %>%
  left_join(pv_df, by = c("year", "party"))

# the only state without six week data are Utah and Idaho. DC, Georgia, Mississippi, South
# dakota, Wyoming all only have 2 observations

data_state_six <- state_pv %>% 
  full_join(state_avg) %>% 
  filter(weeks_left == 6) %>% 
  group_by(state,year,party, pv, incumbent_party) %>% 
  summarise(avg_support=mean(avg_poll)) %>%
  filter(!(state %in% c("ME-1","ME-2","NE-1","NE-2","NE-3")))

data_state_sev <- state_pv %>%
  full_join(state_avg) %>%
  filter(state %in% c("Idaho", 
                      "Delaware",
                      "Alaska",
                      "Utah",
                      "District of Columbia", 
                      "Georgia",
                      "Mississippi",
                      "South Dakota",
                      "Wyoming",
                      "Hawaii",
                      "Kentucky",
                      "North Dakota"), weeks_left == 7) %>%
  group_by(state,year,party, pv, incumbent_party) %>% 
  summarise(avg_support=mean(avg_poll))

# still only two observations for Idaho so adding week 8

data_state_eight <- state_pv%>%
  full_join(state_avg) %>%
  filter(state %in% c("Idaho", "Wyoming", "District of Columbia"), weeks_left == 8) %>%
  group_by(state,year,party, pv, incumbent_party) %>% 
  summarise(avg_support=mean(avg_poll))

# this data has all 51 states for pre 2020

pre_2020_data <- bind_rows(data_state_six, data_state_sev, data_state_eight)

# getting data for 2020
{
  poll_2020_url <- "https://projects.fivethirtyeight.com/2020-general-data/presidential_poll_averages_2020.csv"
  poll_2020_df <- read_csv(poll_2020_url)
  
  elxnday_2020 <- as.Date("11/3/2020", "%m/%d/%Y")
  dnc_2020 <- as.Date("8/20/2020", "%m/%d/%Y")
  rnc_2020 <- as.Date("8/27/2020", "%m/%d/%Y")
  
  colnames(poll_2020_df) <- c("year","state","poll_date","candidate_name","avg_support","avg_support_adj")
  
  # this data has all states except for Illinois, Nebraska, South Dakota,
  # Wyoming, DC, Rhode Island. Those states do not have local polls available
  # from 538
  
  poll_2020_six <- poll_2020_df %>%
    mutate(party = case_when(candidate_name == "Donald Trump" ~ "republican",
                             candidate_name == "Joseph R. Biden Jr." ~ "democrat"),
           poll_date = as.Date(poll_date, "%m/%d/%Y"),
           days_left = round(difftime(elxnday_2020, poll_date, unit="days")),
           weeks_left = round(difftime(elxnday_2020, poll_date, unit="weeks")),
           before_convention = case_when(poll_date < dnc_2020 & party == "democrat" ~ TRUE,
                                         poll_date < rnc_2020 & party == "republican" ~ TRUE,
                                         TRUE ~ FALSE),
           incumbent_party = if_else(party == "republican", TRUE, FALSE)) %>%
    filter(!is.na(party)) %>%
    filter(!(state %in% c("National","ME-1","ME-2","NE-1","NE-2","NE-3"))) %>%
    filter(weeks_left == 7) %>%
    group_by(state, party, incumbent_party) %>%
    summarise(avg_support = mean(avg_support), .groups = "drop")
}


# why are states missing? this is the unique set of states that we have
# predictions for for 2020. I guess I will predict other states somehow else.


####### state models in sample fits ##########

library(rsample)


######### 2020 predictions #########

## creating list of voting bumps. non comp is .4*comp coeff

covid_pop <- covid_pop %>%
  mutate(coef = if_else(state %in% competitive, .000095, .000095*.4),
         bump = aid_per_case * coef)


new_unique <- unique(poll_2020_six$state)

results_2020 <- tibble()

for(s in new_unique){
  
  # incumbent model
  
  temp_data_inc <- pre_2020_data %>% filter(state == s, incumbent_party==TRUE)
  
  temp_mod_inc <- lm(pv ~ avg_support, data = temp_data_inc)
  
  #challenger model
  
  temp_data_chl <- pre_2020_data %>% filter(state == s, incumbent_party==FALSE)
  
  temp_mod_chl <- lm(pv ~ avg_support, data = temp_data_chl)
  
  # incumbent 2020 data
  
  temp_2020_inc <- poll_2020_six %>%
    filter(state  == s, incumbent_party == TRUE) %>%
    slice(1) %>%
    pull(avg_support)
  
  inc_df <- data.frame(avg_support = temp_2020_inc)
  
  # challenger 2020 data
  
  temp_2020_chl <- poll_2020_six %>%
    filter(state == s, incumbent_party == FALSE) %>%
    slice(1) %>%
    pull(avg_support)
  
  chl_df <- data.frame(avg_support = temp_2020_chl)
  
  # trump bump
  b <- covid_pop %>%
    filter(state == s) %>%
    pull(bump)
  
  #incumbent prediction
  
  inc <- predict(temp_mod_inc, newdata = inc_df, 
                 interval = "prediction", level=.95) %>%
    round(digits = 2) + b
  

  
  # challenger prediction
  
  chl <- predict(temp_mod_chl, newdata = chl_df,
                 interval = "prediction", level=.95) %>%
    round(digits = 2)
  
  inc_party <- "republican"
  
  chl_party <- "democrat"
  
  temp_df <- tibble(state = s,
                    republican = if_else(inc_party == "republican", inc[[1]], chl[[1]]),
                    r_interval = paste(inc[[2]], inc[[3]], sep = "-"),
                    democrat = if_else(inc_party == "democrat", inc[[1]], chl[[1]]),
                    d_interval = paste(chl[[2]], chl[[3]], sep = "-"))
  
  
  results_2020 <- results_2020 %>% bind_rows(temp_df)
  
  
}

# putting in electoral votes

results_2020_ec <- results_2020 %>%
  left_join(EC, by ="state") %>%
  mutate(winner = if_else(republican > democrat, "republican", "democrat"))

# missing data from 2020

missing <- EC %>% filter(state %in% c("Illinois",
                                      "Nebraska",
                                      "Rhode Island",
                                      "South Dakota",
                                      "Vermont",
                                      "Wyoming",
                                      "District of Columbia")) %>%
  mutate(winner = case_when(state == "Illinois" ~ "democrat",
                            state == "Nebraska" ~ "republican",
                            state == "Rhode Island" ~ "democrat",
                            state == "South Dakota" ~ "republican",
                            state == "Vermont" ~ "democrat",
                            state == "Wyoming" ~ "republican",
                            state == "District of Columbia" ~ "democrat"),
         republican = if_else(winner == "republican", 100, 0),
         democrat = if_else(winner == "democrat", 100, 0)) %>%
  select(state, republican, democrat, votes, winner)


# combining missing and 2020 data

results_2020_plus <- results_2020_ec %>%
  bind_rows(missing) %>%
  mutate(win_margin = case_when(state == "Illinois" ~ -16.9,
                                state == "Nebraska" ~ 25.1,
                                state == "Rhode Island" ~ -15.5,
                                state == "South Dakota" ~ 29.8,
                                state == "Vermont" ~ -26.4,
                                state == "Wyoming" ~ 46.3,
                                state == "District of Columbia" ~ -86.9,
                                TRUE ~ republican - democrat))

sums <- results_2020_plus %>%
  group_by(winner) %>%
  summarise(c =  sum(votes))

conservative_sums <- sums
conservative_results <- results_2020_plus

conservative_map <- plot_usmap(data = conservative_results, regions = "states", values = "win_margin") +
  scale_fill_gradient2(
    high = "red", 
    mid = "white",
    low = "blue", 
    breaks = c(-50,-25,0,25,50), 
    limits = c(-50,50),
    name = "win margin") +
  theme_void() +
  labs(title = "Win Margins Predictions 2020 Conservative Coefficient",
       subtitle = "Biden wins 368 electoral votes\n Trump wins 170 electoral votes",
       fill = "Win Margin") +
  theme_void() +
  theme(
    strip.text = element_text(size = 12),
    plot.title = element_text(hjust = .5),
    plot.subtitle = element_text(hjust = .5),
    aspect.ratio = 1
  )


base_sums <- sums
base_results <- results_2020_plus

###### creating map of 2020 results  #######

library(usmap)
states_map <- usmap::us_map()
unique(states_map$abbr)

base_map <- plot_usmap(data = base_results, regions = "states", values = "win_margin") +
  scale_fill_gradient2(
    high = "red", 
    mid = "white",
    low = "blue", 
    breaks = c(-50,-25,0,25,50), 
    limits = c(-50,50),
    name = "win margin") +
  theme_void() +
  labs(title = "Win Margins Predictions 2020 Base Coefficient",
       subtitle = "Biden wins 339 electoral votes\n Trump wins 199 electoral votes",
       fill = "Win Margin") +
  theme_void() +
  theme(
    strip.text = element_text(size = 12),
    plot.title = element_text(hjust = .5),
    plot.subtitle = element_text(hjust = .5),
    aspect.ratio = 1
  )


nc_sums <- sums
nc_results <- results_2020_plus
nc_map <- plot_usmap(data = nc_results, regions = "states", values = "win_margin") +
  scale_fill_gradient2(
    high = "red", 
    mid = "white",
    low = "blue", 
    breaks = c(-50,-25,0,25,50), 
    limits = c(-50,50),
    name = "win margin") +
  theme_void() +
  labs(title = "Win Margins Predictions 2020 Less Conservative Coefficient",
       subtitle = "Biden wins 321 electoral votes\n Trump wins 217 electoral votes",
       fill = "Win Margin") +
  theme_void() +
  theme(
    strip.text = element_text(size = 12),
    plot.title = element_text(hjust = .5),
    plot.subtitle = element_text(hjust = .5),
    aspect.ratio = 1
  )

conservative_sums <- sums
conservative_results <- results_2020_plus

conservative_map <- plot_usmap(data = conservative_results, regions = "states", values = "win_margin") +
  scale_fill_gradient2(
    high = "red", 
    mid = "white",
    low = "blue", 
    breaks = c(-50,-25,0,25,50), 
    limits = c(-50,50),
    name = "win margin") +
  theme_void() +
  labs(title = "Win Margins Predictions 2020 Conservative Coefficient",
       subtitle = "Biden wins 368 electoral votes\n Trump wins 170 electoral votes",
       fill = "Win Margin") +
  theme_void() +
  theme(
    strip.text = element_text(size = 12),
    plot.title = element_text(hjust = .5),
    plot.subtitle = element_text(hjust = .5),
    aspect.ratio = 1
  )



ggarrange(conservative_map, base_map, nc_map)




#### creating weightings. weighting so mean is either increased by 1, 2, or 3 %

trump_bump <- covid_pop %>%
  mutate(
         less = .000095*aid_per_case,
         base = .00019*aid_per_case,
         more = .000285*aid_per_case) %>%
  pivot_longer(cols = c(base, less, more), names_to = "type", values_to = "plus")

comp_bumbs <- trump_bump %>%
  filter(state %in% competitive) %>%
  ggplot(aes(x = state, y = plus, fill = type)) +
  geom_col(position = "dodge") +
  coord_flip() +
  theme_classic() +
  labs(title = "Vote Increases from Different Estimated Coefficients",
subtitle = "Competitive States",
y = "Vote Share Increase",
x = "")  +
  scale_fill_brewer(palette = "Blues",
                    name = "Coefficient",
                    labels = c(".00019", ".000095", ".000285")) +
  theme(
    strip.text = element_text(size = 12),
    plot.title = element_text(size = 18),
    plot.subtitle = element_text(size = 16),
    aspect.ratio = 1,
    axis.title = element_text(size=16),
    axis.text = element_text(size=13, color = "black")
  )

ggsave("Gov1347-master/figures/covid_bump_comp.png")




  


