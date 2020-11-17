library(gsheet)
library(tidyverse)
library(ggplot2)
library(webshot)
library(kableExtra)
library(gt)
library(statebins)
library(reshape2)
library(stargazer)
library(rsample)
library(janitor)
library(ggpubr)
library(ggrepel)
library(Metrics)

# getting current election results from csv

results <- read_csv("Gov1347-master/data/popvote_bystate_1948-2020.csv") %>%
  filter(year == 2020) %>%
  mutate(biden_pop_vote = D / total,
         trump_pop_vote = R / total,
         biden_margin = 100*(biden_pop_vote - trump_pop_vote))

# reading in final prediction data

preds <- readRDS("Gov1347-master/data/final_predictions.rds")

# joining data sets

pred_results_c <- preds %>%
  select(state, 
         votes,
         biden_pred = dem,
         trump_pred = rep,
         pred_win_margin = win_margin,
         pred_winner = winner) %>%
  inner_join(results, by = "state") %>%
  mutate(actual_winner = if_else(biden_margin > 0,
                                 "democrat",
                                 "republican"))

# creating side by side maps

prediction_plot <- pred_results_c %>%  ##`statebins` needs state to be character, not factor!
  mutate(state = as.character(state)) %>%
  ggplot(aes(state = state, fill = pred_winner)) +
  geom_statebins() +
  theme_statebins() +
  scale_fill_manual(values = c("steelblue2", "indianred")) +
  labs(title = "2020 Presidential Election Prediction",
       subtitle = "Biden Wins with 356 Electoral Votes",
       fill = "") +
  theme(legend.position = "none")

results_plot <- pred_results_c %>%  ##`statebins` needs state to be character, not factor!
  mutate(state = as.character(state)) %>%
  ggplot(aes(state = state, fill = actual_winner)) +
  geom_statebins() +
  theme_statebins() +
  scale_fill_manual(values = c("steelblue2", "indianred")) +
  labs(title = "2020 Presidential Election Results (11/12/2020)",
       subtitle = "Biden Wins with 306 Electoral Votes",
       fill = "") +
  theme(legend.position = "none")

ggarrange(prediction_plot, results_plot)


# showing close ups of states I got wrong (FL, NC, IA)

pred_results_c %>%
  filter(state %in% c("Florida", "North Carolina", "Iowa")) %>%
  pivot_longer(cols = c(pred_win_margin, biden_margin),
               names_to = "model",
               values_to = "point") %>%
  ggplot(aes(x = state, y = point, fill = model)) +
  geom_col(position = "dodge", width = .5) +
  scale_fill_manual(values = c("indianred", "steelblue2"),
                    name = "",
                    labels = c("Actual Margin", "Predicted Margin")) +
  coord_flip() +
  theme_classic() +
  labs(x = "",
       y = "Biden Vote Margin",
       title = "Missing States Winn Margins",
       subtitle = "Trump wins tight races NC, IA, FL")


# doing plot of how win margins are

pred_results_c$state_ab <- state.abb[match(pred_results_c$state, state.name)]

pred_vs_actual_margins <-  pred_results_c %>%
  ggplot(aes(x = pred_win_margin, y = biden_margin, label = state_ab)) +
  geom_vline(xintercept = 0, size = .25) +
  geom_hline(yintercept = 0,  size = .25) +
  geom_abline(intercept = 0, slope = 1, color = "blue",
              linetype = "dashed") +
  geom_text(check_overlap = TRUE) +
    theme_classic() +
  labs(title = "Actual vs Predicted Biden Vote Margin",
       subtitle = "Model tended to underestimate Trump",
       x = "Predicted Margin",
       y = "Actual Margin")

# plot of errors. This is actual minus predicted

errors <- pred_results_c %>%
  mutate(error = biden_margin - pred_win_margin) %>%
  select(state, error) %>%
  arrange(error) %>%
  ggplot(aes(x = reorder(state, error), y = error)) +
  geom_col(fill = "indianred") +
  coord_flip() +
  theme_classic() +
  labs(title = "Prediction Errors",
       subtitle = "Model systematically underestimated Trump",
       x = "",
       y = "Prediction Error")

ggarrange(pred_vs_actual_margins, errors)

RMSE_all <- rmse(actual = pred_results_c$biden_margin, predicted = pred_results_c$pred_win_margin)

# battleground states

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

pred_battleground <- pred_results_c %>%
  filter(state %in% battleground)

pred_not_battleground <- pred_results_c %>%
  filter(!state %in% battleground)

RMSE_bg <- rmse(actual = pred_battleground$biden_margin, predicted = pred_battleground$pred_win_margin)
RMSE_nbg <- rmse(actual = pred_not_battleground$biden_margin, predicted = pred_not_battleground$pred_win_margin)

RMSE_tab <- tibble(States = c("All States", "Battleground States", "Non Battleground States"),
                   RMSE = c(RMSE_all, RMSE_bg, RMSE_nbg)) %>%
  gt() %>%
  tab_header(title = "Model RMSE",
             subtitle = "Model performed better in Battleground States")

