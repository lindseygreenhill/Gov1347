## Updated 2020 presidential forecast incorporating polling data

library(tidyverse)
library(ggplot2)
library(webshot)
library(kableExtra)
library(gt)
library(statebins)
library(stargazer)
library(rsample)

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

# filtering out na values from dat_change

dat_change <- dat_change %>%
  drop_na()

# subsetting the data 
df_pivot <- dat_change %>%
  pivot_wider(names_from = party,
              values_from = c(pv, avg_support))

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
  
  poll_2020_three <- poll_2020_df %>%
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
    filter(weeks_left == 3) %>%
    group_by(state, party, incumbent_party) %>%
    summarise(avg_support = mean(avg_support), .groups = "drop")
}

dem_2020 <- poll_2020_three %>%
  filter(party == "democrat", state != "District of Columbia")
rep_2020 <- poll_2020_three %>%
  filter(party == "republican", state != "District of Columbia")

# predicting 2020 with poll only model

results_dem <- data.frame(pred = predict(mod_dem_polls, newdata = dem_2020),
                        state = state.abb)

results_rep <- data.frame(pred = predict(mod_rep_polls, newdata = rep_2020),
                          state = state.abb)

poll_mod_results <- results_dem %>%
  left_join(results_rep, by = "state",
            suffix = c("_dem", "_rep")) %>%
  mutate(winner = if_else(pred_dem > pred_rep, "democrat",
                          "republican"))

# graphic of state bin prediction results (need to count EC)

plot_poll_mod <- poll_mod_results %>%  ##`statebins` needs state to be character, not factor!
  mutate(state = as.character(state)) %>%
  ggplot(aes(state = state, fill = winner)) +
  geom_statebins() +
  theme_statebins() +
  scale_fill_manual(values = c("steelblue2", "indianred")) +
  labs(title = "2020 Presidential Election Prediction",
       subtitle = "Poll Only Model",
       fill = "") +
  theme(legend.position = "none")

# predicting 2020 with poll + demographics model 

dem_2020$state_ab <- state.abb[match(dem_2020$state, state.name)]

dem_2020_demog <- dem_2020 %>%
  left_join(demog_2020_change, by = c("state_ab" = "state")) %>%
  select(state_ab, avg_support,
         Black_change, 
         Hispanic_change,
           Asian_change,
           Female_change)

# prediction

results_dem_plus <- data.frame(pred = predict(mod_dem_polls_dem, newdata = dem_2020_demog),
                          state = state.abb)

# need to use prior republican results because we don't have a model for republican vote share.

plus_mod_results <- results_dem_plus %>%
  left_join(results_rep, by = "state",
            suffix = c("_dem", "_rep")) %>%
  mutate(winner = if_else(pred_dem > pred_rep, "democrat",
                          "republican"))

# graphic of state bin prediction results (need to count EC)

plot_plus_mod <- plus_mod_results %>%  ##`statebins` needs state to be character, not factor!
  mutate(state = as.character(state)) %>%
  ggplot(aes(state = state, fill = winner)) +
  geom_statebins() +
  theme_statebins() +
  scale_fill_manual(values = c("steelblue2", "indianred")) +
  labs(title = "2020 Presidential Election Prediction",
       subtitle = "Poll and Demographics Model",
       fill = "") +
  theme(legend.position = "none")


# okay I now want to compare how this model performs historically compared to
# only state models which I can take code from from my polls script. Also I want
# to show those distributions in a histogram or soemthing. And then I want to
# weight those compared to how sparse the data is

### Model Selection: In sample Sample Evaluation ########


### Model Selection: Out of Sample Evaluation ########
mod_rep_polls <- lm(pv_republican ~ avg_support, data = df_pivot)

mod_dem_polls_dem <- mod_dem_polls <- lm(pv_democrat ~ avg_support + 
                                           Black_change + 
                                           Hispanic_change +
                                           Asian_change +
                                           Female_change, data = df_pivot)

outsamp <- tibble()

for(s in unique(dat_change$state)){
  outsamp_df <- tibble()
  
  # get subsetted data for each state
  
  temp_data_s <- dat_change %>%
    filter(state == s)
  
  # getting list of years for that state
  
  all_years <- unique(temp_data_s$year)
  
  # getting dem data
  
  temp_dem <- temp_data_s %>%
    filter(party == "democrat")
  
  # getting rep data
  
  temp_rep <- temp_data_s %>%
    filter(party == "republican")
  
  # for state only model. not sure if this will work because of rows
  
  outsamp_dflist <- lapply(all_years, function(year){
    true_dem <- unique(temp_data_s$year == year & temp_data_s$party == "democrat")
    true_rep <- unique(temp_data_s$year == year & temp_data_s$party == "republican")
    
    # model for dem and rep with only state df MIGHT BE PROBLEM WITH NAs
    
    mod_state_dem <- lm(pv ~ avg_support + 
                          Black_change + 
                          Hispanic_change +
                          Asian_change +
                          Female_change, data = temp_dem)
    mod_state_rep <- lm(pv ~ avg_support, data = temp_rep)
    
    # creating prediction from those models 
    
    pred_state_dem <- predict(mod_state_dem, temp_dem[temp_dem$year == year,])
    pred_state_rep <- predict(mod_state_rep, temp_rep[temp_rep$year == year,])
    
    cbind.data.frame(year,
                     state_margin_error = (pred_state_dem - pred_state_rep) - (true_dem - true_rep),
                     state_winner_correct = (pred_state_dem > pred_state_rep) == (true_dem > true_rep))
  })
  
  # creating error for state
  
  outsamp_df <- do.call(rbind, outsamp_dflist) %>%
    mutate(state = s)
  
  # adding error to main accuracy df
  
  outsamp <- outsamp %>%
    bind_rows(outsamp_df)
}

for(s in unique(dat_change$state)){
  outsamp_df <- tibble()
  
  # get subsetted data for each state
  
  temp_data_s <- dat_change %>%
    filter(state == s)
  
  # getting list of years for that state
  
  all_years <- unique(temp_data_s$year)
  
  # getting dem data
  
  temp_dem <- temp_data_s %>%
    filter(party == "democrat")
  
  # getting rep data
  
  temp_rep <- temp_data_s %>%
    filter(party == "republican")
  
  # for state only model. not sure if this will work because of rows
  
  outsamp_dflist <- lapply(all_years, function(year){
    true_dem <- unique(temp_data_s$year == year & temp_data_s$party == "democrat")
    true_rep <- unique(temp_data_s$year == year & temp_data_s$party == "republican")
    
    # model for dem and rep with only state df MIGHT BE PROBLEM WITH NAs
    
    mod_state_dem <- lm(pv ~ avg_support + 
                          Black_change + 
                          Hispanic_change +
                          Asian_change +
                          Female_change, data = temp_dem)
    mod_state_rep <- lm(pv ~ avg_support, data = temp_rep)
    
    # creating prediction from those models 
    
    pred_state_dem <- predict(mod_state_dem, temp_dem[temp_dem$year == year,])
    pred_state_rep <- predict(mod_state_rep, temp_rep[temp_rep$year == year,])
    
    cbind.data.frame(year,
                     state_margin_error = (pred_state_dem - pred_state_rep) - (true_dem - true_rep),
                     state_winner_correct = (pred_state_dem > pred_state_rep) == (true_dem > true_rep))
  })
  
  # creating error for state
  
  outsamp_df <- do.call(rbind, outsamp_dflist) %>%
    mutate(state = s)
  
  # adding error to main accuracy df
  
  outsamp <- outsamp %>%
    bind_rows(outsamp_df)
}

# states that I can build models off of
counts <- dat_change %>% group_by(state, party) %>% count() %>%
  filter(n > 2)

unique(counts$state)

accuracy_state_mods <- tibble()
for(s in unique(counts$state)){
  #print(s)
  outsamp_df <- tibble()
  
  # get subsetted data for each state
  
  temp_data_s <- dat_change %>%
    filter(state == s)
  
  # getting list of years for that state
  
  all_years <- unique(temp_data_s$year)
  
  # getting dem data
  
  temp_dem <- temp_data_s %>%
    filter(party == "democrat")
  
  # getting rep data
  
  temp_rep <- temp_data_s %>%
    filter(party == "republican")
  
  for(y in all_years){
    
    # true dem for that year 
    
    true_dem <- temp_data_s %>%
      filter(year == y,
             party == "democrat")
    
    
    # true rep for that year 
    
    true_rep <- temp_data_s %>%
      filter(year == y,
             party == "republican")
    
    # dem model df
    
    dem_pred_df <- temp_dem %>%
      filter(year != y)
    
    # rep model df
    
    rep_pred_df <- temp_rep %>%
      filter(year != y)
    
    # dem model 
    
    mod_state_dem <- lm(pv ~ avg_support +
                          Black_change +
                          Hispanic_change +
                          Asian_change +
                          Female_change, data = dem_pred_df)
    
    # rep model
    
    mod_state_rep <- lm(pv ~ avg_support, data = rep_pred_df)
    
    # creating predictions
    
    pred_state_dem <- predict(mod_state_dem, newdata = true_dem)
    pred_state_rep <- predict(mod_state_rep, newdata = true_rep)
    #print(pred_state_dem)
    
    tib <- tibble(state = s,
                  year = y,
                  state_winner_correct = (pred_state_dem > pred_state_rep) == (true_dem$pv > true_rep$pv))
    
    accuracy_state_mods <- accuracy_state_mods %>%
      bind_rows(tib)
    
    
  }
  
}

accuracy_pooled <- tibble()
for(s in unique(dat_change$state)){
  
  # get subsetted data for each state
  
  temp_data_s <- dat_change %>%
    filter(state == s)
  
  # getting list of years for that state
  
  all_years <- unique(temp_data_s$year)
  
  # getting dem data. This is different temporary df as above because it is
  # pooled model and it used all the states
  
  temp_dem <- dat_change %>%
    filter(party == "democrat")
  
  temp_rep <- dat_change %>%
    filter(party == "republican")
  
  for(y in all_years){
    
    # true dem for that year. this is for an individual state year
    
    true_dem <- temp_data_s %>%
      filter(year == y,
             party == "democrat")
    # print(true_dem)
    
    
    # true rep for that year 
    
    true_rep <- temp_data_s %>%
      filter(year == y,
             party == "republican")
    
    # dem model df. getting rid of one state year observation
    
    dem_pred_df <- temp_dem %>%
      filter(!(state == s & year == y))
    
    # rep model df
    
    rep_pred_df <- temp_rep %>%
      filter(!(state == s & year == y))
    
    # dem model 
    
    mod_pooled_dem <- lm(pv ~ avg_support +
                          Black_change +
                          Hispanic_change +
                          Asian_change +
                          Female_change, data = dem_pred_df)
    
    # rep model
    
    mod_pooled_rep <- lm(pv ~ avg_support, data = rep_pred_df)
    
    # creating predictions
    
    pred_state_dem <- predict(mod_pooled_dem, newdata = true_dem)
    pred_state_rep <- predict(mod_pooled_rep, newdata = true_rep)
    #print(pred_state_dem)
    
    tib <- tibble(state = s,
                  year = y,
                  state_winner_correct = (pred_state_dem > pred_state_rep) == (true_dem$pv > true_rep$pv))
    
    accuracy_pooled <- accuracy_pooled %>%
      bind_rows(tib)
    
    
  }
  
}

accuracy_combined <- accuracy_state_mods %>%
  bind_rows(accuracy_pooled, .id = "model") %>%
  mutate(model = if_else(model == 1, "state", "pooled")) %>%
  group_by(model, state) %>%
  summarize(avg_correct = mean(state_winner_correct)) %>%
  arrange(state)
  
  