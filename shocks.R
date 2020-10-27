library(tidyverse)
library(ggplot2)
library(webshot)
library(kableExtra)
library(gt)
library(statebins)
library(janitor)
library(stargazer)
library(rsample)
library(ggpubr)
library(gganimate)

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

## state pop ##
state_pop <- read_csv("Gov1347-master/data/state_pop.csv") %>%
  clean_names() %>%
  select(state = name, population = popestimate2019)

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
                                "poll_date" = "date")) %>%
  left_join(state_pop, by = "state") %>%
  mutate(case_per_cap = tot_cases / population,
         death_per_cap = tot_death / population) %>%
  group_by(state) %>%
  mutate(poll_change = avg_support - lag(avg_support, order_by = poll_date),
         death_rate = tot_death / tot_cases)

covid_poll <- covid_poll %>%
  mutate(cases_per_hun_thous = case_per_cap * 100000)

## battleground states ###

battleground <- c("Arizona", "Georgia",
                  "Ohio",
                  "Florida",
                  "New Hampshire",
                  "Nevada",
                  "Michigan",
                  "Pennsylvania",
                  "Minnesota",
                  "Wisconsin",
                  "Michigan",
                  "North Carolina")

## looking at new cases per day ##

covid_poll %>%
  filter(state %in% battleground) %>%
  ggplot(aes(x = poll_date, y = new_case)) +
  geom_point(alpha = .4) +
  facet_wrap(~state) +
  theme_classic() +
  labs(x = "Date",
       y = "New Cases",
       title = "New Covid-19 Cases in Battleground States") +
  theme(plot.title = element_text(size = 16),
        axis.text = element_text(size = 13),
        axis.title = element_text(size = 14))

ggsave("Gov1347-master/figures/cases_by_day_bg.png")


covid_poll %>%
  filter(state %in% battleground) %>%
  ggplot(aes(x = new_case, y = avg_support)) +
  geom_point() +
  geom_smooth(method = "lm") +
  facet_wrap(~state) +
  theme_classic() +
  labs(title = "Trump Poll Support vs New Cases",
       subtitle = "Battleground States",
       y = "Average Support",
       x = "New Cases") +
  theme(plot.title = element_text(size = 16),
        plot.subtitle = element_text(size = 15),
        axis.text = element_text(size = 13),
        axis.title = element_text(size = 14))

# looking at cases per capita

case_per_hun <- covid_poll %>%
  filter(state %in% battleground) %>%
  ggplot(aes(x = poll_date, y = cases_per_hun_thous)) +
  geom_point(alpha = .4) +
  facet_wrap(~state) +
  theme_classic() +
  labs(x = "Date",
       y = "Cases per 100,000 people",
       title = "Covid-19 Cases in Battleground States") +
  theme(plot.title = element_text(size = 16),
        axis.text = element_text(size = 13),
        axis.title = element_text(size = 14))



supp_vs_cases <- covid_poll %>%
  filter(state %in% battleground) %>%
  ggplot(aes(x = cases_per_hun_thous, y = avg_support)) +
  geom_point() +
  geom_smooth(method = "lm") +
  facet_wrap(~state) +
  theme_classic() +
  labs(title = "Trump Poll Support vs Cases per 100,000",
       subtitle = "Battleground States",
       y = "Average Support",
       x = "Cases per 100,000") +
  theme(plot.title = element_text(size = 16),
        plot.subtitle = element_text(size = 15),
        axis.text = element_text(size = 13),
        axis.title = element_text(size = 14))

ggarrange(case_per_hun, supp_vs_cases)





## looking at death rate ##

death_rt_time <- covid_poll %>%
  filter(state %in% battleground) %>%
  ggplot(aes(x = poll_date, y = death_rate)) +
  geom_point(alpha = .4) +
  facet_wrap(~state) +
  theme_classic() +
  labs(x = "Date",
       y = "Death Rate",
       title = "Covid-19 Death Rate in Battleground States") +
  theme(plot.title = element_text(size = 16),
        axis.text = element_text(size = 13),
        axis.title = element_text(size = 14))

ggsave("Gov1347-master/figures/death_rate_by_day_bg.png")



death_rate_vs_poll <- covid_poll %>%
  filter(state %in% battleground) %>%
  ggplot(aes(x = death_rate, y = avg_support)) +
  geom_point() +
  geom_smooth(method = "lm") +
  facet_wrap(~state) +
  theme_classic() +
  labs(title = "Trump Poll Support vs Death Rate",
       y = "Average Support",
       x = "Death Rate") +
  theme(plot.title = element_text(size = 16),
        plot.subtitle = element_text(size = 15),
        axis.text = element_text(size = 13),
        axis.title = element_text(size = 14))

ggsave("Gov1347-master/figures/death_rate_vs_poll_bg.png")

ggarrange(death_rt_time, death_rate_vs_poll)

## doing animation of new cases per day for whole country ##

covid_animation <- covid_poll %>%
  ggplot(aes(state = state, fill = new_case)) +
  geom_statebins() +
  transition_time(poll_date) +
  theme_classic() +
  scale_fill_continuous(name = "New Cases",
                    high = "indianred",
                    low = "steelblue2") +
  labs(title = "Date: {frame_time}")

a  <- animate(covid_animation, nframes = 400, duration = 40,
        fps = 5, end_pause = 10, rewind = TRUE)

magick::image_write(a, path="Gov1347-master/figures/new_cases.gif")

covid_poll <- covid_poll %>%
  mutate(battleground = if_else(state %in% battleground,
                                1,
                                0))

covid_capita_animation <- covid_poll %>%
  ggplot(aes(state = state, fill = cases_per_hun_thous)) +
  geom_statebins() +
  transition_time(poll_date) +
  theme_classic() +
  scale_fill_continuous(name = "Cases per 100,000",
                        high = "indianred",
                        low = "steelblue2") +
  labs(title = "Covid-19 Cases per 100,000",
       subtitle = "Date: {frame_time}") +
  theme(plot.title = element_text(size = 16),
        plot.subtitle = element_text(size = 15),
        axis.text = element_text(size = 13),
        axis.title = element_text(size = 14))

a_2  <- animate(covid_capita_animation, nframes = 400, duration = 40,
              fps = 5, end_pause = 10, rewind = TRUE)

magick::image_write(a_2, path="Gov1347-master/figures/case_per_hun.gif")
  

summary(lm(poll_change ~ death_per_cap, data = covid_poll))

summary(lm(poll_change ~ death_per_cap*battleground, data = covid_poll))



summary(lm(poll_change ~ new_death, data = covid_poll))

ggplot(covid_poll, aes(x = new_death, y = poll_change)) +
  geom_point()

ggplot(covid_poll, aes(x = death_per_cap, y = poll_change)) +
  geom_point()

ggplot(covid_poll, aes(x = case_per_cap, y = poll_change)) +
  geom_point()



lm(avg_support ~ cases_per_hun_thous + state, data = covid_poll)

ggplot(covid_poll, aes(x = cases_per_hun_thous,y = poll_change)) +
  geom_point(alpha = .5)+
  theme_classic() +
  geom_smooth(method = "lm") +
  labs(title = "Poll Change vs. Cases per 100,000",
       subtitle = "Seemingly no correlation",
       x = "Cases per 100,000",
       y = "Poll Change") +
  theme(plot.title = element_text(size = 16),
        plot.subtitle = element_text(size = 15),
        axis.text = element_text(size = 13),
        axis.title = element_text(size = 14))

ggsave("Gov1347-master/figures/poll_change_vs_cases.png")



