## Updated 2020 presidential forecast incorporating polling data

library(tidyverse)
library(ggplot2)

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
                      "Utah",
                      "District of Columbia", 
                      "Georgia",
                      "Mississippi",
                      "South Dakota",
                      "Wyoming"), weeks_left == 7) %>%
  group_by(state,year,party, pv, incumbent_party) %>% 
  summarise(avg_support=mean(avg_poll))

# still only two observations for Idaho so adding week 8

data_state_eight <- state_pv%>%
  full_join(state_avg) %>%
  filter(state == "Idaho", weeks_left == 8) %>%
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
  
  #incumbent prediction
  
  inc <- predict(temp_mod_inc, newdata = inc_df)
  
  # challenger prediction
  
  chl <- predict(temp_mod_chl, newdata = chl_df)
  
  inc_party <- "republican"
  
  chl_party <- "democrat"
  
  temp_df <- tibble(state = s,
                    republican = if_else(inc_party == "republican", inc, chl),
                    democrat = if_else(inc_party == "democrat", inc, chl))
  
  
  results_2020 <- results_2020 %>% bind_rows(temp_df)
  
  
}

# putting in electoral votes

results_2020_ec <- results_2020 %>%
  left_join(EC, by ="state") %>%
  mutate(winner = if_else(republican > democrat, "republican", "democrat"))

sums <- results_2020_ec %>%
  group_by(winner)%>%
  summarise(c =  sum(votes))


### Model Selection: Classification Accuracy ########

all_years <- seq(from=1972, to=2016, by=4)
outsamp_dflist <- lapply(all_years, function(year){
  true_inc <- unique(datadata_state$year == year & data_state$incumbent_party)
  
  
})

accuracy <- tibble()


for(s in unique(pre_2020_data$state)){
  
  outsamp_df <- tibble()
  
  # getting data  for each state
  
  temp_data <- pre_2020_data %>%
    filter(state == s)
  #print(temp_data)
  
  # getting list of years  for each state
  
  all_years <- unique(pre_2020_data$year[pre_2020_data$state == s])
  
  # getting incumbent data for each state
  
  temp_inc <- temp_data %>%
    filter(incumbent_party)
  
  # getting challenger data for each state
  
  temp_chl <- temp_data %>%
    filter(!incumbent_party)
  
  
  #trying to recreate this from function
   
    outsamp_dflist <- lapply(all_years, function(year){
      true_inc<- unique(temp_data$pv[temp_data$year == year & temp_data$incumbent_party])
      true_chl <- unique(temp_data$pv[temp_data$year == year & !temp_data$incumbent_party])
     
      # creating model for inc and chl. data frames come from above
      
      mod_state_inc <- lm(pv ~ avg_support, data = temp_inc[temp_inc$year != year,])
      mod_state_chl <- lm(pv ~ avg_support, data = temp_chl[temp_chl$year != year,])
      
      # creating predictions from those models
      
     pred_poll_inc <- predict(mod_state_inc, temp_inc[temp_inc$year == year,])
      pred_poll_chl <- predict(mod_state_chl, temp_chl[temp_chl$year == year,])
      
      cbind.data.frame(year,
                       state_margin_error = (pred_poll_inc - pred_poll_chl) - (true_inc - true_chl),
                       state_winner_correct = (pred_poll_inc > pred_poll_chl) == (true_inc > true_chl))
      
      
    })
    
    # creating error for state
    
    outsamp_df <-  do.call(rbind, outsamp_dflist) %>%
      mutate(state = s)
    colMeans()
    
    # adding error to main accuracy df
    
    accuracy <- accuracy %>%
      bind_rows(outsamp_df)
    
}


accuracy_org <- accuracy %>%
  select(year, state, state_margin_error, state_winner_correct) %>%
  group_by(state) %>%
  summarise(mean_ME = mean(state_margin_error),
            mean_correct =  mean(state_winner_correct),
            .groups = "drop") %>%
  arrange(desc(mean_correct))








