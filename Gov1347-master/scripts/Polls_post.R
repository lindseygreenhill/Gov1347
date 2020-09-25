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


###### code from section of finding cross sample validation ########

dat <- popvote_df %>% 
  full_join(poll_df %>% 
              filter(weeks_left == 6) %>% 
              group_by(year,party) %>% 
              summarise(avg_support=mean(avg_support))) %>% 
  left_join(economy_df %>% 
              filter(quarter == 2))

#####------------------------------------------------------#
#####  Proposed models ####
#####------------------------------------------------------#
library(ggplot2)
library(ggrepel)
library(ggpubr)

### polls incumbent graph ###
inc_dat <- dat %>% filter(incumbent_party)
inc_plot <- ggplot(inc_dat, aes(x = avg_support, y = pv)) +
  geom_point() +
  geom_smooth(method = "lm") +
  theme_classic() +
  labs(title = "Popular Vote Share vs Avg Poll Support (Incumbent)",
       x = "Avg Poll Support",
       y = "Popular Vote Share") +
  theme(plot.title = element_text(size = 20),
        axis.title = element_text(size=16),
        axis.text = element_text(size=13)) +
  geom_label_repel(aes(label = year),
                   box.padding = .35,
                   point.padding = .5,
                   segment.color = "grey50")

### polls challenger graph ###
chl_dat <- dat %>% filter(!incumbent_party)
chl_plot <- ggplot(chl_dat, aes(x = avg_support, y = pv)) +
  geom_point() +
  geom_smooth(method = "lm") +
  theme_classic() +
  labs(title = "Popular Vote Share vs Avg Poll Support (Challenger)",
       x = "Avg Poll Support",
       y = "Popular Vote Share") +
  theme(plot.title = element_text(size = 20),
        axis.title = element_text(size=16),
        axis.text = element_text(size=13)) +
  geom_label_repel(aes(label = year),
                   box.padding = .35,
                   point.padding = .5,
                   segment.color = "grey50")

ggarrange(inc_plot, chl_plot)

## option 1: fundamentals-only model
dat_econ <- unique(dat[!is.na(dat$GDP_growth_qt),])
dat_econ_inc <- dat_econ[dat_econ$incumbent_party,]
dat_econ_chl <- dat_econ[!dat_econ$incumbent_party,]
mod_econ_inc <- lm(pv ~ GDP_growth_qt, data = dat_econ_inc)
mod_econ_chl <- lm(pv ~ GDP_growth_qt, data = dat_econ_chl)

## option 2: adjusted polls-only model
dat_poll <- dat[!is.na(dat$avg_support),]
dat_poll_inc <- dat_poll[dat_poll$incumbent_party,]
dat_poll_chl <- dat_poll[!dat_poll$incumbent_party,]
mod_poll_inc <- lm(pv ~ avg_support, data = dat_poll_inc)
mod_poll_chl <- lm(pv ~ avg_support, data = dat_poll_chl)

## option 3: adjusted polls + fundamentals model
dat_plus <- dat[!is.na(dat$avg_support) & !is.na(dat$GDP_growth_qt),]
dat_plus_inc <- dat_plus[dat_plus$incumbent_party,]
dat_plus_chl <- dat_plus[!dat_plus$incumbent_party,]
mod_plus_inc <- lm(pv ~ avg_support + GDP_growth_qt, data = dat_plus_inc)
mod_plus_chl <- lm(pv ~ avg_support + GDP_growth_qt, data = dat_plus_chl)

#####------------------------------------------------------#
#####  Model selection: In-sample evaluation ####
#####------------------------------------------------------#

## interpret models
summary(mod_econ_inc)
summary(mod_econ_chl)

summary(mod_poll_inc)
summary(mod_poll_chl)

summary(mod_plus_inc)
summary(mod_plus_chl)


## in-sample fit
mean(abs(mod_econ_inc$residuals))
mean(abs(mod_econ_chl$residuals))

mean(abs(mod_poll_inc$residuals))
mean(abs(mod_poll_chl$residuals))

mean(abs(mod_plus_inc$residuals))
mean(abs(mod_plus_chl$residuals))

## data taken from summaries above

chl_mod_sum <- tibble(Model = "Challenger",
                      Estimate = .49,
                      Adj_R_squared = .34,
                      MSE = 2.588)
inc_mod_sum <- tibble(Model = "Incumbent",
                      Estimate = .72,
                      Adj_R_squared = .79,
                      MSE = 2.16)

poll_mod_summary <- bind_rows(inc_mod_sum, chl_mod_sum)
kable_sum <- poll_mod_summary %>%
  kable() %>%
  tab_header(title = "Regression Results (PV ~ Avg_Support)")

gt_sum <- poll_mod_summary %>%
  gt() %>%
  tab_header(title = "Regression Results (PV ~ Avg_Support)")

library(webshot)

# saving the table as an image

gtsave(gt_sum, "Gov1347-master/figures/national_reg_table.png")

par(mfrow=c(3,2))
{
  plot(mod_econ_inc$fitted.values, dat_econ_inc$pv,
       main="fundamentals (incumbent)", xlab="predicted", ylab="true", 
       cex.lab=2, cex.main=2, type='n',xlim=c(40,65),ylim=c(40,65))
  text(mod_econ_inc$fitted.values, dat_econ_inc$pv, dat_econ_inc$year)
  abline(a=0, b=1, lty=2)
  
  plot(mod_econ_chl$fitted.values, dat_econ_chl$pv,
       main="fundamentals (challenger)", xlab="predicted", ylab="true", 
       cex.lab=2, cex.main=2, type='n',xlim=c(40,55),ylim=c(40,55))
  text(mod_econ_chl$fitted.values, dat_econ_chl$pv, dat_econ_chl$year)
  abline(a=0, b=1, lty=2)
  
  plot(mod_poll_inc$fitted.values, dat_poll_inc$pv,
       main="polls (incumbent)", xlab="predicted", ylab="true", 
       cex.lab=2, cex.main=2, type='n',xlim=c(40,55),ylim=c(40,55))
  text(mod_poll_inc$fitted.values, dat_poll_inc$pv, dat_poll_inc$year)
  abline(a=0, b=1, lty=2)
  
  plot(mod_poll_chl$fitted.values, dat_poll_chl$pv,
       main="polls (challenger)", xlab="predicted", ylab="true", 
       cex.lab=2, cex.main=2, type='n',xlim=c(40,55),ylim=c(40,55))
  text(mod_poll_chl$fitted.values, dat_poll_chl$pv, dat_poll_chl$year)
  abline(a=0, b=1, lty=2)
  
  plot(mod_plus_inc$fitted.values, dat_plus_inc$pv,
       main="plus (incumbent)", xlab="predicted", ylab="true", 
       cex.lab=2, cex.main=2, type='n',xlim=c(40,55),ylim=c(40,55))
  text(mod_plus_inc$fitted.values, dat_plus_inc$pv, dat_plus_inc$year)
  abline(a=0, b=1, lty=2)
  
  plot(mod_plus_chl$fitted.values, dat_plus_chl$pv,
       main="plus (challenger)", xlab="predicted", ylab="true", 
       cex.lab=2, cex.main=2, type='n',xlim=c(40,55),ylim=c(40,55))
  text(mod_plus_chl$fitted.values, dat_plus_chl$pv, dat_plus_chl$year)
  abline(a=0, b=1, lty=2)
}

#####------------------------------------------------------#
#####  Model selection: Out-of-sample evaluation ####
#####------------------------------------------------------#

all_years <- seq(from=1948, to=2016, by=4)
outsamp_dflist <- lapply(all_years, function(year){
  
  true_inc <- unique(dat$pv[dat$year == year & dat$incumbent_party])
  true_chl <- unique(dat$pv[dat$year == year & !dat$incumbent_party])
  
  ##fundamental model out-of-sample prediction
  mod_econ_inc_ <- lm(pv ~ GDP_growth_qt, data = dat_econ_inc[dat_econ_inc$year != year,])
  mod_econ_chl_ <- lm(pv ~ GDP_growth_qt, data = dat_econ_chl[dat_econ_chl$year != year,])
  pred_econ_inc <- predict(mod_econ_inc_, dat_econ_inc[dat_econ_inc$year == year,])
  pred_econ_chl <- predict(mod_econ_chl_, dat_econ_chl[dat_econ_chl$year == year,])
  
  if (year >= 1980) {
    ##poll model out-of-sample prediction
    mod_poll_inc_ <- lm(pv ~ avg_support, data = dat_poll_inc[dat_poll_inc$year != year,])
    mod_poll_chl_ <- lm(pv ~ avg_support, data = dat_poll_chl[dat_poll_chl$year != year,])
    pred_poll_inc <- predict(mod_poll_inc_, dat_poll_inc[dat_poll_inc$year == year,])
    pred_poll_chl <- predict(mod_poll_chl_, dat_poll_chl[dat_poll_chl$year == year,])
    
    
    ##plus model out-of-sample prediction
    mod_plus_inc_ <- lm(pv ~ GDP_growth_qt + avg_support, data = dat_plus_inc[dat_poll_inc$year != year,])
    mod_plus_chl_ <- lm(pv ~ GDP_growth_qt + avg_support, data = dat_plus_chl[dat_poll_chl$year != year,])
    pred_plus_inc <- predict(mod_plus_inc_, dat_plus_inc[dat_plus_inc$year == year,])
    pred_plus_chl <- predict(mod_plus_chl_, dat_plus_chl[dat_plus_chl$year == year,])
  } else {
    pred_poll_inc <- pred_poll_chl <- pred_plus_inc <- pred_plus_chl <- NA
  }
  
  cbind.data.frame(year,
                   econ_margin_error = (pred_econ_inc-pred_econ_chl) - (true_inc-true_chl),
                   poll_margin_error = (pred_poll_inc-pred_poll_chl) - (true_inc-true_chl),
                   plus_margin_error = (pred_plus_inc-pred_plus_chl) - (true_inc-true_chl),
                   econ_winner_correct = (pred_econ_inc > pred_econ_chl) == (true_inc > true_chl),
                   poll_winner_correct = (pred_poll_inc > pred_poll_chl) == (true_inc > true_chl),
                   plus_winner_correct = (pred_plus_inc > pred_plus_chl) == (true_inc > true_chl)
  )
})
outsamp_df <- do.call(rbind, outsamp_dflist)
colMeans(abs(outsamp_df[2:4]), na.rm=T)
colMeans(outsamp_df[5:7], na.rm=T) ### classification accuracy

outsamp_df[,c("year","econ_winner_correct","poll_winner_correct","plus_winner_correct")]





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

insamp <- tibble()

for(s in unique(pre_2020_data$state)){
  
  # temp data
  
  temp_data_inc <- pre_2020_data %>%
    filter(state == s, incumbent_party == TRUE)
  
  temp_data_chl <- pre_2020_data %>%
    filter(state == s, incumbent_party == FALSE)
  
  # state models
  
  mod_inc <- lm(pv ~ avg_support, data = temp_data_inc)
  mod_chl <- lm(pv ~ avg_support, data = temp_data_chl)
  
  # summarising
  
  sum_inc <- summary(mod_inc)
  #print(sum_inc)
  sum_chl <- summary(mod_chl)
  
  # errors
  
  mean(abs(mod_inc$residuals))
  mean(abs(mod_chl$residuals))
  
  vector_inc <- tibble(State = s,
                       Model = "Incumbent",
                       Estimate = sum_inc$coefficients[2,1],
                       MSE = mean(abs(mod_inc$residuals)),
                       Adj_R_Squared = sum_inc$adj.r.squared
                       )
  vector_chl <- tibble(State = s,
                       Model = "Challenger",
                       Estimate = sum_chl$coefficients[2,1],
                       MSE = mean(abs(mod_chl$residuals)),
                       Adj_R_Squared = sum_chl$adj.r.squared
  )
  
  insamp <- insamp %>%
    bind_rows(vector_inc, vector_chl)
  
}

insamp_gt <- insamp %>%
  mutate_if(is.numeric, ~round(., 3)) %>%
  gt()

gtsave(insamp_gt, "Gov1347-master/figures/tab.png")

### R squared histogram

r_df_2 <- tibble(Model = c("Challenger", "Incumbent")) %>%
  mutate(Adj_R_squared = if_else(Model == "Challenger", .34, .79))

r_hist <- insamp %>%
  ggplot(aes(Adj_R_Squared)) +
  geom_vline(data = r_df_2, aes(xintercept = Adj_R_squared, color = "red")) +
  geom_histogram(bins = 22) +
  facet_wrap(~Model) +
  theme_classic() +
  labs(title = "Distribution of Adjusted R Squared Values for 51 State Models",
       subtitle = "Distributions for both the incumbent and challenger models included",
       x = "Adjusted R Squared",
       y = "Count") +
  theme(plot.title = element_text(size = 20),
        axis.title = element_text(size=16),
        axis.text = element_text(size=13),
        legend.position = "none")





######### 2020 predictions #########


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
  
  inc <- predict(temp_mod_inc, newdata = inc_df, 
                 interval = "prediction", level=.95) %>%
    round(digits = 2)
  
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


###### creating map of 2020 results  #######

library(usmap)
states_map <- usmap::us_map()
unique(states_map$abbr)

plot_usmap(data = results_2020_plus, regions = "states", values = "win_margin") +
  scale_fill_gradient2(
    high = "red", 
    # mid = scales::muted("purple"), ##TODO: purple or white better?
    mid = "white",
    low = "blue", 
    breaks = c(-50,-25,0,25,50), 
    limits = c(-50,50),
    name = "win margin") +
  theme_void() +
  labs(title = "Win Margins Predictions 2020",
       subtitle = "Biden wins 377 electoral votes\n Trump wins 161 electoral votes",
       fill = "Win Margin") +
  theme_void() +
  theme(
    strip.text = element_text(size = 12),
    plot.title = element_text(hjust = .5),
    plot.subtitle = element_text(hjust = .5),
    aspect.ratio = 1
  )

ggsave("Gov1347-master/figures/polls_mod_prediction_map.png")
### Model Selection: Classification Accuracy ########

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
    # colMeans()
    
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

# histogram of classification accuracy

accuracy_hist <- accuracy_org %>%
  ggplot(aes(mean_correct)) +
  geom_histogram(bins = 45) +
  geom_vline(xintercept = .9, color = "red") + 
  annotate("text", x = .78, y = 20, label = "National Model\n Classification Accuracy",
           color = "red", size = 5) +
  theme_classic() +
  labs(title = "Distribution of Classification Accuracy for 51 State Models",
       subtitle = "Some models outperform national model, some underperform national model",
       x = "Classification Accuracy",
       y = "Count") +
  theme(plot.title = element_text(size = 20),
        plot.subtitle = element_text(size = 16),
        axis.title = element_text(size=16),
        axis.text = element_text(size=13))

ggsave("Gov1347-master/figures/poll_state_classification_hist.png")

accuracy_gt <- accuracy_org %>%
  mutate_if(is.numeric, ~round(.,3)) %>%
  rename(State = state, Avg_Err = mean_ME, 
         Classification_Accuracy = mean_correct) %>%
  gt()

gtsave(accuracy_gt, "Gov1347-master/figures/accuracy_table.png")

accuracy_kable <- accuracy_org %>%
  mutate_if(is.numeric, ~round(.,3)) %>%
  rename(State = state, Avg_Err = mean_ME, 
         Classification_Accuracy = mean_correct) %>%
  kable() %>%
  kable_material()

save_kable(accuracy_kable, "Gov1347-master/figures/accuracy_kable.png")


### next steps: see the cross sample validation for the national polls

#### predicting 2020 with national model ######

# avg support taken from 538 data
biden <- tibble(avg_support = 50.312)
trump <- tibble(avg_support = 43.396)
biden_prediction <- predict(mod_poll_chl, newdata = biden)
trump_prediction <- predict(mod_poll_inc, newdata = trump)








