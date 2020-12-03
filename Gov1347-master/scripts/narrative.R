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


ns_df_1 %>%
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
  theme_classic()


ns_df_1 %>%
  drop_na() %>%
  ggplot(aes(x = is_hispanic, y = vote_2020)) +
  geom_point(position = "jitter")

is_h_fit <- lm(vote_2020 ~ is_hispanic, data = ns_df_1)
summary(is_h_fit)

ns_df_2 <- lm(vote_2020 ~ factor(hispanic),  data = ns_df_1)
summary(ns_df_2)

ns_df_1 %>%
  ggplot(aes(x = is_hispanic, y = vote_2020, col = factor(hispanic))) +
  geom_point(position = "jitter")
