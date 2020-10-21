library(tidyverse)
library(ggplot2)
library(webshot)
library(kableExtra)
library(gt)
library(statebins)
library(stargazer)
library(rsample)
library(ggpubr)

#### reading in data ####


popvote_df <- read_csv("Gov1347-master/data/popvote_1948-2016.csv")
poll_df    <- read_csv("Gov1347-master/data/pollavg_1968-2016.csv")

pv_df  <- popvote_df %>%
  select(year, party,incumbent_party)

# reading in electoral college data

vector <- data.frame(state = "District of Columbia", votes = 3)
EC <- read_csv("Gov1347-master/data/electoral_college.csv") %>%
  select(state = State, votes = electoralVotesNumber) %>%
  bind_rows(vector)

# state poll data

state_avg <- read_csv("Gov1347-master/data/pollavg_bystate_1968-2016.csv")



# state pv data

state_pv <- read_csv("Gov1347-master/data/popvote_bystate_1948-2016.csv") %>%
  mutate(republican = (R / total) * 100, democrat = (D/total) * 100) %>%
  pivot_longer(cols = c("republican", "democrat"), names_to = "party",
               values_to = "pv") %>%
  select(year,state, party, pv) %>%
  filter(year >= 1972) %>%
  left_join(pv_df, by = c("year", "party"))

## 2020 polling data ###

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
  
  poll_2020 <- poll_2020_df %>%
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
    group_by(state, party, incumbent_party, poll_date) %>%
    summarise(avg_support = mean(avg_support), .groups = "drop")
  }

poll_2020_inc <- poll_2020 %>%
  filter(party == "republican")

poll_2020_inc$state_ab <- state.abb[match(poll_2020_inc$state, state.name)]

### 2020 state level covid data #####

covid_state <- read_csv("Gov1347-master/data/state_covid.csv") %>%
  select(submission_date, state, tot_cases, new_case, tot_death, new_death) %>%
  mutate(date = as.Date(submission_date, "%m/%d/%Y")) %>%
  select(-submission_date)

covid_poll <- poll_2020_inc %>%
  left_join(covid_state, by = c("state_ab" = "state",
                                "poll_date" = "date"))

