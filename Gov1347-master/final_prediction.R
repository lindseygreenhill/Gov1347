## Updated 2020 presidential forecast incorporating polling data

library(tidyverse)
library(ggplot2)
library(webshot)
library(kableExtra)
library(gt)
library(statebins)
library(stargazer)
library(rsample)
library(ggpubr)

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

data_state_one <- state_pv %>% 
  full_join(state_avg) %>% 
  filter(weeks_left == 1) %>% 
  group_by(state,year,party, pv) %>% 
  summarise(avg_support=mean(avg_poll)) %>%
  filter(!(state %in% c("ME-1","ME-2","NE-1","NE-2","NE-3")))

data_state_one$state_ab <- state.abb[match(data_state_one$state, state.name)]


# reading in demographic data

demog <- read_csv("Gov1347-master/data/demographic_1990-2018.csv")

dem_poll_state_df <- data_state_one %>%
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

mod_dem_polls <- lm(pv_democrat ~ avg_support_democrat, data = df_pivot)
mod_rep_polls <- lm(pv_republican ~ avg_support_republican, data = df_pivot)

mod_dem_polls_dem <- lm(pv_democrat ~ avg_support_democrat + 
                          Black_change + 
                          Hispanic_change +
                          Asian_change +
                          Female_change +
                          White_change +
                          age20_change +
                          age3045_change +
                          age4565_change, data = df_pivot)



stargazer(mod_dem_polls_dem, mod_rep_polls,
          title = "Democrat and Republican Pooled Models",
          out = "Gov1347-master/figures/star_final.html")

stargazer( mod_dem_polls_dem, mod_rep_polls,
          type = "text")



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
  
  poll_2020_one <- poll_2020_df %>%
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
    filter(weeks_left == 1) %>%
    group_by(state, party, incumbent_party) %>%
    summarise(avg_support = mean(avg_support), .groups = "drop")
}

dem_2020 <- poll_2020_one %>%
  filter(party == "democrat", state != "District of Columbia") %>%
  rename(avg_support_democrat = avg_support)
rep_2020 <- poll_2020_one %>%
  filter(party == "republican", state != "District of Columbia") %>%
  rename(avg_support_republican = avg_support)

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
  select(state, avg_support_democrat,
         Black_change, 
         Hispanic_change,
         Asian_change,
         Female_change,
         White_change,
         age20_change,
        age3045_change,
           age4565_change)

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
    
    mod_state_dem <- lm(pv ~ avg_support, data = dem_pred_df)
    print(summary(mod_state_dem))
    
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
                           Female_change +
                           White_change +
                           age20_change +
                           age3045_change +
                           age4565_change, data = dem_pred_df)
    
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
                  "North Carolina",
                  "Iowa",
                  "Texas")

accuracy_combined <- accuracy_state_mods %>%
  bind_rows(accuracy_pooled, .id = "model") %>%
  mutate(model = if_else(model == 1, "state", "pooled")) %>%
  group_by(model, state) %>%
  summarize(avg_correct = mean(state_winner_correct)) %>%
  arrange(state) %>%
  mutate(status = if_else(state %in% battleground,
                          "battleground",
                          "not_battleground"))

acc_2 <- accuracy_combined %>%
  pivot_wider(names_from = model,
              values_from = avg_correct,
              names_prefix = "accuracy_")

bg <- accuracy_combined %>%
  filter(status == "battleground")

nbg <- accuracy_combined %>%
  filter(status != "battleground")

plot_bg <- bg %>%
  ggplot(aes(x = state, y = avg_correct, fill = model))+
  geom_col(position = position_dodge(width = .5)) +
  theme_classic() +
  scale_fill_manual(values = c("dodgerblue3", "coral2"),
                    name =  "Model") +
  labs(title = "Model Performance: Classification Accuracy",
       subtitle = "Battleground States",
       y = "Accuracy",
       x = ""
  ) +
  coord_flip() +
  theme(plot.title = element_text(size = 16),
        plot.subtitle = element_text(size = 16),
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 14),
        legend.position = "bottom")

plot_nbg <- nbg %>%
  ggplot(aes(x = state, y = avg_correct, fill = model))+
  geom_col(position = position_dodge(width = .5)) +
  theme_classic() +
  scale_fill_manual(values = c("dodgerblue3", "coral2"),
                    name =  "Model") +
  labs(title = "Model Performance: Classification Accuracy",
       subtitle = "Non-Battleground States",
       y = "Accuracy",
       x = ""
  ) +
  coord_flip() +
  theme(plot.title = element_text(size = 16),
        plot.subtitle = element_text(size = 16),
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 14),
        legend.position = "bottom")

ggarrange(plot_bg, plot_nbg)

ggsave("Gov1347-master/figures/demog_mods_classifications_final.png")

## going to do weighting based off of model performance. If performed equally, going to 
# give  a .5 and  .5. If one of them  outperformed I'm going to give them .75 and .25


## doing 2020 predictions with weighted ensemble model ######
# models without state data get 100% of weight put on pooled (
# Utah, Vermont, Rhode Island, New Mexico, Connecticut)

weights <- acc_2 %>%
  mutate(weight_pooled = if_else(accuracy_pooled == accuracy_state, .8,
                                 if_else(accuracy_pooled > accuracy_state, 1, .5)),
         weight_state = 1 - weight_pooled) %>%
  mutate(weight_pooled = if_else(state %in% c("Montana",
                                              "Delaware",
                                              "South Carolina",
                                              "Mississippi",
                                              "Kansas"), 1,
                                 weight_pooled),
         weight_state = 1  - weight_pooled)

# predictions 

# these are the pooled models I just took from above code


# doing loop to predict all states

results_base <- tibble()

for(s in unique(acc_2$state)){
  print(s)
  
  # extracting weights
  
  pooled_w <- weights$weight_pooled[weights$state == s]
  state_w <- weights$weight_state[weights$state == s]
  
  #print(pooled_w)
  
  # state data
  
  temp_data_dem <- dat_change %>%
    filter(state == s, party == "democrat") %>%
    rename(avg_support_democrat = avg_support)
  
  temp_data_rep <- dat_change %>%
    filter(state == s, party == "republican")  %>%
    rename(avg_support_republican = avg_support)
  
  # dem model state
  
  mod_state_dem <- lm(pv ~ avg_support_democrat, data = temp_data_dem)
  
  # rep model state
  
  mod_state_rep <- lm(pv ~ avg_support_republican, data = temp_data_rep)
  
  # prediction data
  
  d_pred_df <- dem_2020_demog %>% 
    filter(state == s)
  r_pred_df <- rep_2020 %>%
    filter(state == s)
  
  # predictions using weights from above
  print(predict(mod_dem_polls_dem, newdata = d_pred_df, interval = "prediction"))
  print(predict(mod_state_dem, newdata = d_pred_df, interval = "prediction"))
  
  dem_prediction <- pooled_w * predict(mod_dem_polls_dem, newdata = d_pred_df) +
    state_w * predict(mod_state_dem, newdata = d_pred_df)
  
  rep_prediction <- pooled_w * predict(mod_rep_polls, newdata = r_pred_df) +
    state_w * predict(mod_state_rep, newdata = r_pred_df)
  


  
  vec <- tibble(state = s,
                dem = dem_prediction,
                rep = rep_prediction)

  
  results_base <- results_base %>%
    bind_rows(vec)
  
  
}



results_base <- results_base %>%
  mutate(winner = if_else(dem > rep, "democrat",
                          "republican")) %>%
  left_join(EC, by = "state") 

missing_states <- EC %>%
  filter(!(state %in% results_base$state))

# getting predictions for missing states

m <- tibble()

for(s in missing_states$state){
  print(s)
  pred_dem <- dem_2020 %>%
    filter(state == s)
  pred_rep <- rep_2020 %>%
    filter(state == s)
  
  dem <- predict(mod_dem_polls, newdata = pred_dem)
  
  rep <- predict(mod_rep_polls, newdata = pred_rep)
  
  vec <- tibble(state = s,
                dem = dem, 
                rep = rep,
                winner = if_else(dem > rep,
                                 "democrat",
                                 "republican"))
  m <- m %>%
    bind_rows(vec)
}

results_base_final <- results_base %>%
  bind_rows(m) %>%
  left_join(EC, by = "state") %>%
  select(-votes.x) %>%
  rename(votes = votes.y) %>%
  mutate(win_margin = dem - rep)

results_base_final_1 <- results_base %>%
  bind_rows(m) %>%
  left_join(EC, by = "state") %>%
  select(-votes.x) %>%
  rename(votes = votes.y) %>%
  mutate(win_margin = dem - rep)


results_base_final_1 %>%
  group_by(winner) %>%
  summarize(votes = sum(votes))

# getting state name abbreviations for state bins function

results_base_final$state_ab <- state.abb[match(results_base_final$state, state.name)]


base_results_plot <- results_base_final_1 %>%  ##`statebins` needs state to be character, not factor!
  mutate(state = as.character(state)) %>%
  ggplot(aes(state = state, fill = winner)) +
  geom_statebins() +
  theme_statebins() +
  scale_fill_manual(values = c("steelblue2", "indianred")) +
  labs(title = "2020 Presidential Election Prediction",
       subtitle = "Biden Wins with 356 Electoral Votes",
       fill = "") +
  theme(legend.position = "none")

ggsave("Gov1347-master/figures/demog_pred_map_final.png")

# win margin plot

base_results_plot_wm <- results_base_final_1 %>%  ##`statebins` needs state to be character, not factor!
  mutate(state = as.character(state)) %>%
  ggplot(aes(state = state, fill = win_margin)) +
  geom_statebins() +
  theme_statebins() +
  scale_fill_gradient2(high = "steelblue2",
                      low = "indianred",
                      mid = "white") +
  labs(title = "2020 Presidential Election Prediction (Win Margin)",
       subtitle = "Biden Wins with 356 Electoral Votes",
       fill = "") +
  theme(legend.position = "none")

ggsave("Gov1347-master/figures/demog_pred_map_wm_final.png")

ggarrange(base_results_plot, base_results_plot_wm)
ggsave("Gov1347-master/figures/final_prediction_map.png")


## in samp fit for pool model

## doing the bootstrapping ### 
# using dat_change





#### experimentation #######

boot_results <- tibble()

for(s in unique(counts$state)){
  
  # prediction data
  
  d_pred <- dem_2020_demog %>% 
    filter(state == s) %>%
    rename(avg_support = avg_support_democrat)
  
  r_pred <- rep_2020 %>%
    filter(state == s) %>%
    rename(avg_support = avg_support_republican)
  
  # weights from classification
  
  pooled_w <- weights$weight_pooled[weights$state == s]
  state_w <- weights$weight_state[weights$state == s]
  
  # boostrapping
  
  boot_size <- 300
  s_vec_dem <- c(rep(NA,boot_size*1000))
  s_vec_rep <- c(rep(NA,boot_size*1000))
  sample_size <- nrow(dat_change)
  
  # # create bootstrapped samples
  for(i in 1:boot_size){
    samp <- sample_n(dat_change, size = sample_size,
                     replace = TRUE)
    #   
    #   # for each sample, build a model for pooled and for state
    #   
    #   # pooled models
    #   
    pooled_mod_dem <- lm(pv ~ avg_support + 
                           Black_change + 
                           Hispanic_change +
                           Asian_change +
                           Female_change +
                           White_change +
                           age20_change +
                           age3045_change +
                           age4565_change, data = samp %>%
                           filter(party == "democrat"))
    #   
    pooled_mod_rep <- lm(pv ~ avg_support,
                         data = samp %>%
                           filter(party == "republican"))
    
    #   # state models
    #   
    state_mod_dem <- lm(pv ~ avg_support, data = samp %>%
                          filter(state == s,
                                 party == "democrat"))
    
    state_mod_rep <- lm(pv ~ avg_support,
                        data = samp %>%
                          filter(state == s,
                                 party == "republican"))
    
    # predict a result from each model using the preassigned weights
    
    dem_pooled_point <- predict(pooled_mod_dem, newdata = d_pred)
    dem_state_point <- predict(state_mod_dem, newdata = d_pred)
    rep_pooled_point <- predict(pooled_mod_rep, newdata = r_pred)
    rep_state_point <- predict(state_mod_rep, newdata = r_pred)
    dem_pooled_se <- summary(pooled_mod_dem)$sigma
    dem_state_se <- summary(state_mod_dem)$sigma
    rep_pooled_se <- summary(pooled_mod_rep)$sigma
    rep_state_se <- summary(state_mod_rep)$sigma

    
    loop <-((i-1)*1000 + 1)
    loop_end <- i*1000
    
    for(j in loop:loop_end){
      dem_prediction <- pooled_w * rnorm(1, mean = dem_pooled_point, sd = dem_pooled_se) +
        state_w * rnorm(1, mean = dem_state_point, sd = dem_state_se)
      rep_prediction <- pooled_w * rnorm(1, mean = rep_pooled_point, sd = rep_pooled_se) +
        state_w * rnorm(1, mean = rep_state_point, sd = rep_state_se)
      
      
      s_vec_dem[j] <- dem_prediction
      s_vec_rep[j] <- rep_prediction
      
    }
    
    
  }
  
  boot_results <- boot_results %>%
    bind_rows(tibble(state = s,
                     dem_results = list(s_vec_dem),
                     rep_results = list(s_vec_rep)))
  
  
  # take the median, 5%, and 95% percentile values from that vector
  # store those numbers in a tibble of results
}
boot_results %>% unnest() %>%
  ggplot() +
  geom_histogram(aes(x = dem_results)) +
  facet_wrap(~state)

boot_results_calc <- boot_results %>%
  unnest(c(dem_results, rep_results)) %>%
  group_by(state) %>%
  summarize(med_dem = median(dem_results),
            fifth_dem = quantile(dem_results, prob = .05),
            nin_f_dem = quantile(dem_results, prob = .95),
            med_rep = median(rep_results),
            fifth_rep = quantile(rep_results, prob = .05),
            nin_f_rep = quantile(rep_results, prob = .95))

ggplot(boot_results_calc, aes(x = state)) +
  geom_pointrange(aes(y = med_dem, ymin = fifth_dem, ymax = nin_f_dem),
                  colour = "blue") +
  geom_pointrange(aes(y = med_rep, ymin = fifth_rep, ymax = nin_f_rep),
                      colour = "red") +
  coord_flip() +
  theme_classic()

bg_intervals <- boot_results_calc %>%
  filter(state %in% battleground) %>%
  ggplot(aes(x = state)) +
  geom_pointrange(aes(y = med_dem, ymin = fifth_dem, ymax = nin_f_dem),
                  colour = "blue") +
  geom_pointrange(aes(y = med_rep, ymin = fifth_rep, ymax = nin_f_rep),
                  colour = "red") +
  coord_flip() +
  theme_classic() +
  labs(title = "Prediction Intervals: Battleground States",
       x = "",
       y = "Popular Vote") +
  theme(plot.title = element_text(size = 16),
        plot.subtitle = element_text(size = 16),
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 14))

nbg_intervals <- boot_results_calc %>%
  filter(!(state %in% battleground)) %>%
  ggplot(aes(x = state)) +
  geom_pointrange(aes(y = med_dem, ymin = fifth_dem, ymax = nin_f_dem),
                  colour = "blue") +
  geom_pointrange(aes(y = med_rep, ymin = fifth_rep, ymax = nin_f_rep),
                  colour = "red") +
  coord_flip() +
  theme_classic() +
  labs(title = "Prediction Intervals: Non-Battleground States",
       x = "",
       y = "Popular Vote") +
  theme(plot.title = element_text(size = 16),
        plot.subtitle = element_text(size = 16),
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 14))

ggarrange(bg_intervals, nbg_intervals)
ggsave("Gov1347-master/figures/final_pred_intervals.png")
# getting in sample statistics for state models 

library(rsample)

insamp <- tibble()

for(s in unique(counts$state)){
  
  # temp data
  samp <- dat_change
  
  
  # state models
    
  state_mod_dem <- lm(pv ~ avg_support, data = samp %>%
                        filter(state == s,
                               party == "democrat"))
  
  state_mod_rep <- lm(pv ~ avg_support,
                      data = samp %>%
                        filter(state == s,
                               party == "republican"))

  
  # summarising
  
  sum_dem <- summary(state_mod_dem)
  #print(sum_inc)
  sum_rep <- summary(state_mod_rep)
  
  # errors
  
  vector_dem <- tibble(State = s,
                       Model = "Democrat",
                       Estimate = sum_dem$coefficients[2,1],
                       MSE = mean(abs(state_mod_dem$residuals)),
                       Adj_R_Squared = sum_dem$adj.r.squared
  )
  vector_rep <- tibble(State = s,
                       Model = "Republican",
                       Estimate = sum_rep$coefficients[2,1],
                       MSE = mean(abs(state_mod_rep$residuals)),
                       Adj_R_Squared = sum_rep$adj.r.squared
  )
  
  insamp <- insamp %>%
    bind_rows(vector_rep, vector_dem)
  
}

d_in <- insamp %>%
  filter(Model == "Democrat") %>%
  drop_na()
r_in <- insamp %>%
  filter(Model == "Republican") %>%
  drop_na()


insamp_dem_hist <-
  ggplot(d_in, aes(x = Adj_R_Squared)) +
  geom_histogram(binwidth = .05) +
  theme_classic() +
  geom_vline(xintercept = .927,
             color = "red",
             linetype = "dotted",
             size = 1.5) +
  labs(title = "Distribution of Adj R Squared: Democrat",
       subtitle = "Pooled Model Adj R Squared = .927",
       x = "Adj R Squared",
       y = "Count")

insamp_rep_hist <-
  ggplot(r_in, aes(x = Adj_R_Squared)) +
  geom_histogram(binwidth = .05) +
  theme_classic() +
  geom_vline(xintercept = .901,
             color = "red",
             linetype = "dotted",
             size = 1.5) +
  labs(title = "Distribution of Adj R Squared: Republican",
       subtitle = "Pooled Model Adj R Squared = .901",
       x = "Adj R Squared",
       y = "Count")

ggarrange(insamp_dem_hist, insamp_rep_hist)
ggsave("Gov1347-master/figures/final_state_r_hist.png")
