#### Introduction ####
#### Gov 1347: Election Analysis (2020)
#### Lindsey Greenhill

# installing packages

library(tidyverse)
library(ggplot2)
library(usmap)

# setting workind directory

# setwd("/Users/lindseygreenhill/Desktop/Elections/Gov1347")

# reading in voting data

popvote_df <- read_csv("data/popvote_1948-2016.csv")

## reading in state data

pvstate_df <- read_csv("data/popvote_bystate_1948-2016.csv")
pvstate_df$full <- pvstate_df$state

# reading in electoral college data
vector <- data.frame(state = "District of Columbia", votes = 3)
EC <- read_csv("data/electoral_college.csv") %>%
  select(state = State, votes = electoralVotesNumber) %>%
  bind_rows(vector)


# creating  maps of last three elections with labels

# shapefile of states from `usmap` library
# note: `usmap` merges this internally, but other packages may not!

states_map <- usmap::us_map()
unique(states_map$abbr)

# this code taken from section

pv_win_map <- pvstate_df %>%
  filter(year >=2008) %>%
  mutate(winner = ifelse(R > D, "Republican", "Democrat"))

# faceting by year to create grid. Adding title and centering title

plot_usmap(
  data = pv_win_map,
  regions = "states",
  values = "winner",
  color = "white"
) +
  facet_wrap(facets = year ~ .) + ## specify a grid by year
  scale_fill_manual(values = c("blue", "red"), name = "PV winner") +
  labs(title = "Election Results 2008-2018") +
  theme_void() +
  theme(
    strip.text = element_text(size = 12),
    plot.title = element_text(hjust = .5),
    aspect.ratio = 1
  )

# saving grid as an image

ggsave("figures/PV_states_grid.png", height = 3, width = 8)

# creating model to predict election. Including last three election cycles 
# because that was the last time a republican was incumbent

# creating a forcasts data frame to store forcasts

forcasts <- data.frame()

# looping through states to add information to forcasts

for(state in unique(pvstate_df$state)){
  state <- state
  
  # calculating the democratic  vote percentage
  
  D_pred_2020 <-
    pvstate_df$D_pv2p[pvstate_df$state == state &
                        pvstate_df$year == 2016] * .7 +
    pvstate_df$D_pv2p[pvstate_df$state == state &
                        pvstate_df$year == 2012] * .2 +
    pvstate_df$D_pv2p[pvstate_df$state == state &
                        pvstate_df$year == 2008] * .1
  
  # calculating the republican vote percentage
  
  R_pred_2020 <-
    pvstate_df$R_pv2p[pvstate_df$state == state &
                        pvstate_df$year == 2016] * .7 +
    pvstate_df$R_pv2p[pvstate_df$state == state &
                        pvstate_df$year == 2012] * .2 +
    pvstate_df$R_pv2p[pvstate_df$state == state &
                        pvstate_df$year == 2008] * .1
  
  # creating a vector to use in bind rows  
  
  vector <-
    data.frame(state = state, year = 2020,
               R_pv2p = R_pred_2020,
               D_pv2p = D_pred_2020)
  
  # binding vector with forcasts
  
  forcasts <- forcasts %>% bind_rows(vector)
}

 forcasts <- forcasts %>% mutate(margins = R_pv2p - D_pv2p)
 
 # mutating to create a win column in forcasts 
 
 forcasts_wins <-
   forcasts %>% mutate(winner = if_else(D_pv2p > R_pv2p, "democrat", "republican"))
 
 # plotting map using blue and red
 
 plot_usmap(
   data = forcasts_wins,
   regions = "states",
   values = "winner",
   color = "white",
   labels = TRUE
 ) +
   scale_fill_manual(values = c("blue", "red"), name = "PV winner") +
   labs(title = "Predicted Election Results 2020") +
   theme_void() +
   theme(
     strip.text = element_text(size = 12),
     plot.title = element_text(hjust = .5),
     aspect.ratio = 1
   )
 
 ggsave("figures/2020_blue_red.png", height = 4, width = 5)
 
 # getting electoral data and using to count electoral votes for 2020
 
 forcasts_EC <- forcasts %>% 
   left_join(EC, by = "state") %>%
   mutate(winner = if_else(D_pv2p > R_pv2p, "D", "R"))
 
 forcasts_EC$votes[state == "District of Columbia"] <- 3
 
 Trump_EC <- 0.0
 
 Biden_EC <- 0.0
 
 for(i in 1:dim(forcasts_EC)[1]){
   row <- forcasts_EC[i,]
   count <- row %>% pull(votes)
   if(row$winner == "R"){
     Trump_EC <- Trump_EC + count
   }
   else{
     Biden_EC <- Biden_EC + count
   }
 }
 
 # combining forcasts data set with pvp data set so I can plot them all in a grid
 
 forcasts_com <-  forcasts %>% select(-margins)
 pvstate_df_com <- pvstate_df  %>% select(state, year, R_pv2p, D_pv2p) %>%
   bind_rows(forcasts_com) %>%
   filter(year >= 2008) %>%
   mutate(win_margin = R_pv2p - D_pv2p)
 
 # creating faceted map of "purple america"
 
 plot_usmap(data = pvstate_df_com, regions = "states", values = "win_margin", color = "white") +
   facet_wrap(facets = year ~.) + ## specify a grid by year
   scale_fill_gradient2(
     high = "red", 
     # mid = scales::muted("purple"), ##TODO: purple or white better?
     mid = "white",
     low = "blue", 
     breaks = c(-50,-25,0,25,50), 
     limits = c(-50,50),
     name = "win margin") +
     theme_void() +
     labs(title = "Win Margins 2008-2020",
     fill = "Win Margin") +
     theme_void() +
     theme(
     strip.text = element_text(size = 12),
     plot.title = element_text(hjust = .5),
     aspect.ratio = 1
   )
 
 ggsave("figures/purple_grid.png", height = 4, width = 5)
 
 
# finding what I consider swing states. Method taken from purple America. 
# Also finding the top ten biggest electoral college states.
 
 top10 <- EC %>% arrange(desc(votes)) %>%
   slice(1:10)
 
 top5swing  <- pv_margins_grid %>% 
   filter(year >= 2008) %>%
   arrange(win_margin)
 
 # how to classify a swing state. Taken from Purple America. 
 # State is blue  is average vote share for  democratic candidate was .51 or greater. Red if democratic Voteshare was .47 or less. They used past four presidential elections
 
 pvstate_df_swing <- data.frame()
 
 for(state in unique(pvstate_df$state)){
   state <- state
   
   # calculating the democratic  vote percentage  average  over four years
   
   D_vote_share <- (pvstate_df$D_pv2p[pvstate_df$state == state & pvstate_df$year == 2016] +
                      pvstate_df$D_pv2p[pvstate_df$state == state & pvstate_df$year == 2012] +
                      pvstate_df$D_pv2p[pvstate_df$state == state & pvstate_df$year == 2008] +
                      pvstate_df$D_pv2p[pvstate_df$state == state & pvstate_df$year == 2004]) / 4
   
   # creating a vector to use in bind rows
   
   vector <- data.frame(state = state, D_pv2p_avg = D_vote_share)
   
   # binding vector with forcasts
   
   pvstate_df_swing <- pvstate_df_swing %>% bind_rows(vector)
 }
 
 top5swing <- pvstate_df_swing %>%
   filter(D_pv2p_avg < 51 & D_pv2p_avg > 47)
 
# creating a graph to  display the movement of the swing states.
# Idea came from professor enos/538
 
 pvstate_df$vote_margin <- pvstate_df$D_pv2p - pvstate_df$R_pv2p
 
 pvstate_df %>% 
   ## subset data
   filter(state %in% c("Florida","Iowa","North Carolina","Ohio","Virginia")) %>%
   filter(year >= 2004) %>%
   ## pipe into ggplot()
   ggplot(aes(x=year, y=vote_margin, color=vote_margin)) + 
   ## specify a grid by state
   facet_wrap(. ~ state,  nrow = 3) + 
   ## add plot elements
   geom_hline(yintercept=0,color="gray") +
   geom_line() + 
   geom_point() +
   ## specify scale colors
   scale_colour_gradient(low = "red", high = "blue") +
   scale_fill_gradient(low = "red", high = "blue") +
   labs(x = "Year",
        y = "Democrat vote-share margin",
        title = "Movement of Swing States since 2004") +
   theme_classic() +
   theme(panel.border = element_blank(),
         plot.title = element_text(size = 18, hjust = .5, face = "bold"),
         legend.position = "none",
         axis.title = element_text(size=12),
         strip.text = element_text(size = 12, face = "bold"))
 
 ggsave("figures/swing_states.png", height = 4, width = 5)
 
 
 
 
 
 
 
 


