library(haven)
library(skimr)
library(janitor)
library(stargazer)
library(tidyverse)

# reading in nation scape data

ns_df <- read_dta("Gov1347-master/data/nationscape.dta") %>%
  select(hispanic, pres_approval, vote_2020)

# need to recode hispanic answers

ns_df_1 <- ns_df %>%
  mutate(hispanic = as_factor(hispanic),
         vote_2020 = as_factor(vote_2020),
         pres_approval = as_factor(pres_approval),
         is_hispanic = if_else(hispanic == "Not Hispanic", 0, 1)) %>%
  filter(vote_2020 %in% c("Donald Trump", "Joe Biden")) %>%
  mutate(vote_lm = if_else(vote_2020 == "Donald Trump", 1, 2))

# regression of vote_lm vs is_hispanic

fit1 <- lm(vote_lm ~ is_hispanic, data = ns_df_1)
summary(fit1)

# regression of factor variables

fit2 <- lm(vote_lm ~ hispanic, data = ns_df_1)
summary(fit2)

# creating stargazer of two regressions

stargazer::stargazer(fit1, fit2, type = "text")

avg_latino <- mean(ns_df_1$vote_lm[ns_df_1$is_hispanic == 1]) - 1

# plot of nationailties

plot_1 <- ns_df_1 %>%
  filter(is_hispanic == 1) %>%
  group_by(hispanic) %>%
  summarise(mean_vote = mean(vote_lm)) %>%
  mutate(mean_vote = mean_vote - 1)  %>%
  ggplot(aes(x = hispanic, y = mean_vote, fill = hispanic)) +
  geom_col() +
  geom_hline(yintercept = avg_latino,
             size = 1.5, linetype = "dashed") +
  scale_y_continuous(limits = c(0,1),
                     breaks = c(0,1),
                     labels = c("Trump", "Biden")) +
  coord_flip()  +
  theme_classic() +
  labs(title = "Avg Vote amongst Nationalities",
        subtitle = "Predicted votes vary greatly",
        x = "Nationality",
        y = "Average Vote")  +
  theme(legend.position = "none")

ggsave("Gov1347-master/figures/narrative_nation_vote.png")

# recoding pres approval to numbers

ns_df_2 <- ns_df_1 %>%
  filter(pres_approval != "Not sure") %>%
  mutate(pres_approval = case_when(pres_approval == "Strongly approve" ~ 1,
                                   pres_approval == "Somewhat approve" ~ 2,
                                   pres_approval == "Somewhat disapprove" ~ 3,
                                   pres_approval == "Strongly disapprove" ~ 4))

ns_df_2 %>% filter(is_hispanic == 1) %>%
  ggplot(aes(x = pres_approval))+
  geom_histogram(binwidth = .5)

fit_3 <- lm(pres_approval ~ is_hispanic, data = ns_df_2)
summary(fit_3)

fit_4 <- lm(pres_approval ~ hispanic, data = ns_df_2)
summary(fit_4)

stargazer::stargazer(fit_3, fit_4, type = "text")

avg_app <- mean(ns_df_2$pres_approval[ns_df_2$is_hispanic == 1])

plot_2 <- ns_df_2 %>%
  filter(is_hispanic == 1) %>%
  group_by(hispanic) %>%
  summarise(mean_app = mean(pres_approval)) %>%
  ggplot(aes(x = hispanic, y = mean_app, fill = hispanic)) +
  geom_col() +
  geom_hline(yintercept = avg_app,
             size = 1.5, linetype = "dashed") +
  scale_y_continuous(limits = c(0,4.5),
                     breaks = c(1,2,3,4),
                     labels = c("Strongly approve", "Somewhat approve",
  "Somewhat disapprove", "Strongly disapprove")) +
  coord_flip()  +
  theme_classic() +
  labs(title = "Avg Approval amongst Nationalities",
       subtitle = "Attitudes vary greatly",
       x = "Nationality",
       y = "Average Approval")  +
  theme(legend.position = "none")


