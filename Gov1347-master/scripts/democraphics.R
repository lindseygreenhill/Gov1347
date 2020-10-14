## Updated 2020 presidential forecast incorporating polling data

library(tidyverse)
library(ggplot2)
library(webshot)
library(kableExtra)
library(gt)
library(stargazer)

#####------------------------------------------------------#
##### Read and merge data ####
#####------------------------------------------------------#

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

# joining state pv and poll data 

data_state_three <- state_pv %>% 
  full_join(state_avg) %>% 
  filter(weeks_left == 3) %>% 
  group_by(state,year,party, pv) %>% 
  summarise(avg_support=mean(avg_poll)) %>%
  filter(!(state %in% c("ME-1","ME-2","NE-1","NE-2","NE-3")))

data_state_three$state_ab <- state.abb[match(data_state_three$state, state.name)]


# reading in demographic data

demog <- read_csv("Gov1347-master/data/demographic_1990-2018.csv")

dem_poll_state_df <- data_state_three %>%
  left_join(demog, by = c("year", "state_ab" = "state"))

# doing something with region from section

demog$region <- state.division[match(demog$state, state.abb)]

dem_poll_state_df$region <- state.division[match(dem_poll_state_df$state_ab, state.abb)]

# creating change data by using the lag function  

dat_change <- dem_poll_state_df %>%
  group_by(state) %>%
  mutate(Asian_change = Asian - lag(Asian, order_by = year),
         Black_change = Black - lag(Black, order_by = year),
         Hispanic_change = Hispanic - lag(Hispanic, order_by = year),
         Indigenous_change = Indigenous - lag(Indigenous, order_by = year),
         White_change = White - lag(White, order_by = year),
         Female_change = Female - lag(Female, order_by = year),
         Male_change = Male - lag(Male, order_by = year),
         age20_change = age20 - lag(age20, order_by = year),
         age3045_change = age3045 - lag(age3045, order_by = year),
         age4565_change = age4565 - lag(age4565, order_by = year),
         age65_change = age65 - lag(age65, order_by = year)
  )

# subsetting the data 
df_pivot <- dat_change %>%
  pivot_wider(names_from = party,
              values_from = pv, 
              names_prefix = "pv_")

# models 

mod_dem_polls <- lm(pv_democrat ~ avg_support, data = df_pivot)
mod_rep_polls <- lm(pv_republican ~ avg_support, data = df_pivot)

mod_dem_polls_dem <- mod_dem_polls <- lm(pv_democrat ~ avg_support + 
                                           Black_change + 
                                           Hispanic_change +
                                           Asian_change +
                                           Female_change, data = df_pivot)

stargazer(mod_dem_polls, mod_dem_polls_dem, type = "text")

mod_dem_demog_change <- lm(pv ~ Black_change + Hispanic_change + Asian_change +
                         Female_change +
                         age3045_change + age4565_change + age65_change +
                         as.factor(region), data = dem_df)

mod_rep_demog_change <- lm(pv ~ Black_change + Hispanic_change + Asian_change +
                             Female_change +
                             age3045_change + age4565_change + age65_change +
                             as.factor(region), data = rep_df)

stargazer(mod_dem_demog_change, type = "text",
          keep = 1:7)

stargazer(mod_dem_demog_change, mod_rep_demog_change, out = "Gov1347-master/figures/star_test.latex",
          header=FALSE, type='latex', no.space = TRUE,
         column.sep.width = "3pt", font.size = "scriptsize", single.row = TRUE,
         keep = c(1:7, 62:66), omit.table.layout = "sn",
         title = "The electoral effects of demographic change (across states)")

# creating visualization of only polls regression

polls_mod_gg <- ggplot(df_pivot, aes(x = avg_support, y = pv_democrat)) +
  geom_point() +
  geom_smooth(method = "lm") +
  theme_classic()

# creating 2020 data (section)

# demographic data

demog_2020_change <- demog %>%
  filter(year %in% c(2016, 2018)) %>%
  group_by(state) %>%
  mutate(Asian_change = Asian - lag(Asian, order_by = year),
         Black_change = Black - lag(Black, order_by = year),
         Hispanic_change = Hispanic - lag(Hispanic, order_by = year),
         Indigenous_change = Indigenous - lag(Indigenous, order_by = year),
         White_change = White - lag(White, order_by = year),
         Female_change = Female - lag(Female, order_by = year),
         Male_change = Male - lag(Male, order_by = year),
         age20_change = age20 - lag(age20, order_by = year),
         age3045_change = age3045 - lag(age3045, order_by = year),
         age4565_change = age4565 - lag(age4565, order_by = year),
         age65_change = age65 - lag(age65, order_by = year)
  ) %>%
  filter(year == 2018)
demog_2020_change <- as.data.frame(demog_2020_change)
rownames(demog_2020_change) <- demog_2020_change$state
demog_2020_change <- demog_2020_change[state.abb, ]

# polling data




  
  