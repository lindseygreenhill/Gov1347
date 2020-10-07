library(tidyverse)
library(ggplot2)
library(geofacet) ## map-shaped grid of ggplots
library(ggthemes)

#####------------------------------------------------------#
##### Read and merge data ####
#####------------------------------------------------------#

pvstate_df    <- read_csv("Gov1347-master/data/popvote_bystate_1948-2016.csv") %>%
  filter(!(state %in% c("ME-1", "ME-2", "NE-1", "NE-2", "NE-3")))
economy_df    <- read_csv("Gov1347-master/data/econ.csv")
pollstate_df  <- read_csv("Gov1347-master/data/pollavg_bystate_1968-2016.csv")
vep_df <- read_csv("Gov1347-master/data/vep_1980-2016.csv")

poll_pvstate_df <- pvstate_df %>%
  inner_join(
    pollstate_df %>% 
      filter(weeks_left == 5)
    # group_by(state, year) %>%
    # top_n(1, poll_date)
  )

poll_pvstate_vep_df <- pvstate_df %>%
  mutate(D_pv = D/total) %>%
  inner_join(pollstate_df %>% filter(weeks_left == 5)) %>%
  left_join(vep_df)

poll_pvstate_df$D_pv <- (poll_pvstate_df$D / poll_pvstate_df$total)*100
poll_pvstate_df$R_pv <- (poll_pvstate_df$R / poll_pvstate_df$total)*100
poll_pvstate_df$state <- state.abb[match(poll_pvstate_df$state, state.name)]

##### current polling data ####
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
  
  poll_2020_five <- poll_2020_df %>%
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
    filter(weeks_left == 5) %>%
    group_by(state, party, incumbent_party) %>%
    summarise(avg_support = mean(avg_support), .groups = "drop")
}


## Get relevant data
VEP_PA_2020 <- as.integer(vep_df$VEP[vep_df$state == "Pennsylvania" & vep_df$year == 2016])

PA_R <- poll_pvstate_vep_df %>% filter(state=="Pennsylvania", party=="republican")
PA_D <- poll_pvstate_vep_df %>% filter(state=="Pennsylvania", party=="democrat")

## Fit D and R models
PA_R_glm <- glm(cbind(R, VEP-R) ~ avg_poll, PA_R, family = binomial)
PA_D_glm <- glm(cbind(D, VEP-D) ~ avg_poll, PA_D, family = binomial)

## Get predicted draw probabilities for D and R
prob_Rvote_PA_2020 <- predict(PA_R_glm, newdata = data.frame(avg_poll=44.5), type="response")[[1]]
prob_Dvote_PA_2020 <- predict(PA_D_glm, newdata = data.frame(avg_poll=50), type="response")[[1]]

## Get predicted distribution of draws from the population
sim_Rvotes_PA_2020 <- rbinom(n = 10000, size = VEP_PA_2020, prob = prob_Rvote_PA_2020)
sim_Dvotes_PA_2020 <- rbinom(n = 10000, size = VEP_PA_2020, prob = prob_Dvote_PA_2020)

## Simulating a distribution of election results: Biden PA PV
hist(sim_Dvotes_PA_2020, xlab="predicted turnout draws for Biden\nfrom 10,000 binomial process simulations", breaks=100)

## Simulating a distribution of election results: Trump PA PV
hist(sim_Rvotes_PA_2020, xlab="predicted turnout draws for Trump\nfrom 10,000 binomial process simulations", breaks=100)

## Simulating a distribution of election results: Biden win margin
sim_elxns_PA_2020 <- ((sim_Dvotes_PA_2020-sim_Rvotes_PA_2020)/(sim_Dvotes_PA_2020+sim_Rvotes_PA_2020))*100
hist(sim_elxns_PA_2020, xlab="predicted draws of Biden win margin (% pts)\nfrom 10,000 binomial process simulations", xlim=c(2, 7.5))


### creating win margin distributions for each state ####

# no data for Nebraska, Rhode Island, South Dakota, Wyoming

poll_pvstate_vep_df_run <- poll_pvstate_vep_df %>%
  filter(!(state %in% c("Nebraska", "Rhode Island", "South Dakota", "Wyoming")))

# creating output data frame
output <- tibble()
tib <- tibble()

for(s in unique(poll_pvstate_vep_df_run$state)){
  
  ## Get relevant data
  
  VEP_s_2020 <- as.integer(vep_df$VEP[vep_df$state == s & vep_df$year == 2016])
  #print(s)
  #print(VEP_s_2020)
   s_R <- poll_pvstate_vep_df %>% filter(state == s, party=="republican")
   
   #print(s_R)
   s_D <- poll_pvstate_vep_df %>% filter(state == s, party=="democrat")
   #print(s_D)
  # 
  ## Fit D and R models
  
    s_R_glm <- glm(cbind(R, VEP-R) ~ avg_poll, s_R, family = binomial)
    s_D_glm <- glm(cbind(D, VEP-D) ~ avg_poll, s_D, family = binomial)
  # 
     r_prob <- poll_2020_five %>%
       filter(state == s, party == "republican") %>%
       select(avg_support)
    # 
     d_prob <- poll_2020_five %>%
       filter(state == s, party == "democrat") %>%
       select(avg_support) 
    # print(d_prob$avg_support)
  #  
  # 
  ## Get predicted draw probabilities for D and 

  
  prob_Rvote_s_2020 <- predict(PA_R_glm, newdata = data.frame(avg_poll=r_prob$avg_support), type="response")[[1]]
  prob_Dvote_s_2020 <- predict(PA_D_glm, newdata = data.frame(avg_poll=d_prob$avg_support), type="response")[[1]]
  
  n <- 10000
  
  ## Get predicted distribution of draws from the population
  sim_Rvotes_s_2020 <- rbinom(n = n, size = VEP_s_2020, prob = prob_Rvote_s_2020)
  sim_Dvotes_s_2020 <- rbinom(n = n, size = VEP_s_2020, prob = prob_Dvote_s_2020)
  
  ## Simulating a distribution of election results: Biden win margin
  sim_elxns_s_2020 <- ((sim_Dvotes_s_2020-sim_Rvotes_s_2020)/(sim_Dvotes_s_2020+sim_Rvotes_s_2020))*100
  
  for(i in 1:n){
    vec <- tibble(state = s, prob = sim_elxns_s_2020[i])
    tib <- tib %>%
      bind_rows(vec)
  }
  vector <- tibble(state = s, sims = list(sim_elxns_s_2020))
  
  output <- output %>%
    bind_rows(vector)
  
}

# creating plot of distributions

poll_mod_preds <- tib %>%
  group_by(state) %>%
  mutate(winner = if_else(mean(prob) > 0, "democrat", "republican"))

ggplot(poll_mod_preds, aes(prob)) +
  geom_histogram(binwidth = 2) +
  geom_rect(aes(fill=winner), xmin=-25, xmax=25, ymin=9900, ymax=11000) +
  facet_geo(~state) +
  scale_fill_manual(values = c("blue", "red")) +
  theme_light() +
  labs(title = "Distributions of Win Margin Predictions",
       subtitle = "Red line at 0% win margin",
       x = "Win Margin (Democrat)",
       y = "Frequency") +
  theme(plot.title = element_text(hjust = .5, size = 18),
        plot.subtitle = element_text(hjust = .5, size = 16)) +
  geom_vline(xintercept = 0, col = "red", size = .4)

library(webshot)

#ggsave("Gov1347-master/figures/poll_prob_model_dist.png")

### key swing states ###

poll_mod_swing_preds <- tib %>%
  filter(state %in% c("Iowa", "Ohio", "North Carolina")) %>%
  group_by(state) %>%
  mutate(winner = if_else(mean(prob) > 0, "democrat", "republican"))

ggplot(poll_mod_swing_preds, aes(prob)) +
  geom_histogram(binwidth = .06) +
  #geom_rect(aes(fill=winner), xmin=-25, xmax=25, ymin=9900, ymax=11000) +
  facet_wrap(~state) +
  #scale_fill_manual(values = c("blue", "red")) +
  theme_classic() +
  labs(title = "Distributions of Win Margin Predictions",
       subtitle = "Red line at 0% win margin",
       x = "Win Margin (Democrat)",
       y = "Frequency") +
  theme(plot.title = element_text(hjust = .5, size = 18),
        plot.subtitle = element_text(hjust = .5, size = 16)) +
  geom_vline(xintercept = 0, col = "red", size = .4)







