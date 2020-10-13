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

  
  prob_Rvote_s_2020 <- predict(s_R_glm, newdata = data.frame(avg_poll=r_prob$avg_support), type="response")[[1]]
  prob_Dvote_s_2020 <- predict(s_D_glm, newdata = data.frame(avg_poll=d_prob$avg_support), type="response")[[1]]
  
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
## ev data ##
vector <- data.frame(state = "District of Columbia", votes = 3)
EC <- read_csv("Gov1347-master/data/electoral_college.csv") %>%
  select(state = State, votes = electoralVotesNumber) %>%
  bind_rows(vector)

## missing state: Vermont, Wyoming, South Dakota, Rhode Island, Nebraska, DC

# creating plot of distributions
missing <- tibble(state = c("Nebraska",
                            "Rhode Island",
                            "South Dakota",
                            "Vermont",
                            "Wyoming",
                            "District of Columbia"),
                  prob = c(-30, 20, -30, 20, -30, 20),
                  winner = if_else(prob < 0, "republican", "democrat"))


# adding a winner column in the predictions tibble

poll_mod_preds <- tib %>%
  group_by(state) %>%
  mutate(winner = if_else(mean(prob) > 0, "democrat", "republican"))

# counting the electoral votes

poll_mod_preds_EC <- poll_mod_preds %>%
  bind_rows(missing) %>%
  left_join(EC, by = "state") %>%
  group_by(state, winner) %>%
  summarise(votes = mean(votes)) %>%
  group_by(winner) %>%
  summarise(total = sum(votes))


# creating map of distributions  

ggplot(poll_mod_preds, aes(prob)) +
  geom_histogram(binwidth = 2) +
  geom_rect(aes(fill=winner), xmin=-25, xmax=25, ymin=9900, ymax=11000) +
  facet_geo(~state) +
  scale_fill_manual(values = c("blue", "red")) +
  theme_light() +
  labs(title = "Distributions of Win Margin Predictions",
       subtitle = "Red line at 0% win margin",
       x = "Win Margin (Democrat)",
       y = "Density") +
  theme(plot.title = element_text(hjust = .5, size = 18),
        plot.subtitle = element_text(hjust = .5, size = 16)) +
  geom_vline(xintercept = 0, col = "red", size = .4)

library(webshot)

ggsave("Gov1347-master/figures/poll_prob_model_dist.png")

### key swing states ###
# make geom_density plot!!

poll_mod_swing_preds <- tib %>%
  filter(state %in% c("Florida", "Wisconsin", "North Carolina")) %>%
  group_by(state) %>%
  mutate(winner = if_else(mean(prob) > 0, "democrat", "republican"))

# histograms of swing states

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

# histogram of indv plot of Swing states
Florida <- poll_mod_preds %>% filter(state == "Florida") %>%
  ggplot(aes(prob, fill = state)) +
  scale_fill_manual(values = "steelblue2")+
  geom_histogram(binwidth = .005) +
  labs(title = "Distributions of Florida\nWin Margin Predictions",
       x = "Win Margin (Democrat)",
       y = "Frequency") +
  theme_classic() +
  theme(plot.title = element_text(size = 18),
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 14),
        legend.position = "none")
Wisconsin <- poll_mod_preds %>% filter(state == "Wisconsin") %>%
  ggplot(aes(prob, fill = state)) +
  scale_fill_manual(values = "steelblue2")+
  geom_histogram(binwidth = .005) +
  labs(title = "Distributions of Wisconsin\n Win Margin Predictions",
       x = "Win Margin (Democrat)",
       y = "Frequency") +
  theme_classic() +
  theme(plot.title = element_text(size = 18),
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 14),
        legend.position = "none")

North_Carolina <- poll_mod_preds %>% filter(state == "North Carolina") %>%
  ggplot(aes(prob, fill = state)) +
  scale_fill_manual(values = "steelblue2")+
  geom_histogram(binwidth = .005) +
  labs(title = "Distributions of North Carolina\n Win Margin Predictions",
       x = "Win Margin (Democrat)",
       y = "Frequency") +
  theme_classic() +
  theme(plot.title = element_text(size = 18),
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 14),
        legend.position = "none")
library(ggpubr)
ggarrange(Florida, Wisconsin, North_Carolina, nrow = 1)
ggsave("Gov1347-master/figures/swing_binomial_preds1.png")

#   
# 
# ggplot(poll_mod_swing_preds, aes(prob, fill = state, ..count..)) +
#   geom_density() +
#   #geom_rect(aes(fill=winner), xmin=-25, xmax=25, ymin=9900, ymax=11000) +
#   #facet_wrap(~state) +
#   #scale_fill_manual(values = c("blue", "red")) +
#   theme_classic() +
#   labs(title = "Distributions of Win Margin Predictions",
#        x = "Win Margin (Democrat)",
#        y = "Count") +
#   theme(plot.title = element_text(size = 18),
#         axis.title = element_text(size = 14),
#         axis.text = element_text(size = 14)) 
#ggsave("Gov1347-master/figures/swing_binomial_preds.png")


## descriptive data: spending found on NPR
## https://www.npr.org/2020/09/15/912663101/biden-is-outspending-trump-on-tv-and-just-6-states-are-the-focus-of-the-campaign
ads_2020 <- tibble(state = c("Wisconsin", "Florida", "North Carolina"),
                   trump = c(31.8, 82.3, 49),
                   biden = c(44.4, 83.5, 37.1)) %>%
  pivot_longer(cols = trump:biden, names_to = "candidate",
               values_to = "spending")

ggplot(ads_2020, aes(x = state, y = spending, fill = candidate)) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = c("blue", "red")) +
  theme_classic() +
  coord_flip() +
  labs(title = "Candidate Ad Spending 2020",
       subtitle = "Biden leads in Wisconsin, Florida",
       x = "",
       y = "Spending ($ Millions)",
       caption = "Data from NPR") +
  theme(axis.text = element_text(size = 14),
        axis.title = element_text(size = 14),
        plot.title = element_text(size = 18),
        plot.subtitle = element_text(size = 16))

ggsave("Gov1347-master/figures/ad_spending_2020.png")


 pred_shifts <- poll_mod_swing_preds %>%
   mutate(shift_Gerber = if_else(state == "Wisconsin", prob - rnorm(10000, 6.5, 1.5),
                            if_else(state == "Florida", prob - rnorm(10000,5.5,1.5),
                                    prob - rnorm(10000, 4.5, 1.5))),
          shift_Huber = if_else(state == "Wisconsin", prob - rnorm(10000, 6.5, 2.5),
                                if_else(state == "Florida", prob - rnorm(10000,5.5,2.5),
                                        prob - rnorm(10000, 4.5, 2.5))))
 
# ggplot(pred_shifts, aes(fill = state)) +
#   geom_histogram(aes(prob, bindwidth = .01)) +
#   geom_histogram(aes(shift_Gerber, binwidth = .01))
#   geom_density(aes(prob, ..scaled..)) +
#   geom_density(aes(shift_Gerber, ..scaled..)) +
#   #geom_density(aes(shift_Huber)) +
#   theme_classic()  

Flo_shifts <- pred_shifts %>%
  filter(state == "Florida") %>%
  ggplot() +
  geom_histogram(aes(shift_Gerber, fill = "indian_red"), alpha = .6) +
  geom_histogram(aes(shift_Huber, fill = "steelblue2"), alpha = .6) +
  labs(title = "Distributions of Adjusted \nFlorida Win Margin",
       x = "Win Margin (Democrat)",
       y = "Frequency") +
  theme_classic() +
  theme(plot.title = element_text(size = 18),
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 14),
        legend.position = "none")

W_shifts <- pred_shifts %>%
  filter(state == "Wisconsin") %>%
  ggplot() +
  geom_histogram(aes(shift_Gerber, fill = "indian_red"), alpha = .6) +
  geom_histogram(aes(shift_Huber, fill = "steelblue2"), alpha = .6) +
  labs(title = "Distributions of Adjusted \nWisconsin Win Margin",
       x = "Win Margin (Democrat)",
       y = "Frequency") +
  theme_classic() +
  theme(plot.title = element_text(size = 18),
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 14),
        legend.position = "none")

NC_shifts <- pred_shifts %>%
  filter(state == "North Carolina") %>%
  ggplot() +
  geom_histogram(aes(shift_Gerber, fill = "indian_red"), alpha = .6) +
  geom_histogram(aes(shift_Huber, fill = "steelblue2"), alpha = .6) +
  labs(title = "Distributions of Adjusted \nNorth Carolina Win Margin",
       x = "Win Margin (Democrat)",
       y = "Frequency") +
  theme_classic() +
  theme(plot.title = element_text(size = 18),
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 14),
        legend.position = "none")

ggarrange(Flo_shifts, W_shifts, NC_shifts, nrow = 1)


ggsave("Gov1347-master/figures/swing_pred_shifts_grps1.png")






