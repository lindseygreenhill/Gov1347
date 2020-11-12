library(gsheet)
library(tidyverse)
library(ggplot2)
library(webshot)
library(kableExtra)
library(gt)
library(statebins)
library(stargazer)
library(rsample)
library(janitor)
library(ggpubr)
library(ggrepel)

# getting current election results from google sheets

results <- gsheet2tbl("https://docs.google.com/spreadsheets/d/1faxciehjNpYFNivz-Kiu5wGl32ulPJhdJTDsULlza5E/edit#gid=0") %>%
  clean_names() %>%
  slice(-1) %>%
  mutate(state = geographic_name,
         total_vote = as.double(total_vote),
         biden_votes = as.double(joseph_r_biden_jr),
         trump_votes = as.double(donald_j_trump),
         biden_pop_vote = biden_votes / total_vote,
         trump_pop_vote = trump_votes / total_vote,
         biden_margin = 100*(biden_pop_vote - trump_pop_vote)) %>%
  select(state, biden_pop_vote, trump_pop_vote, biden_margin)

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
# RMSE calculations

# first doing trump RMSE. Right now it's really high mostly because of NY. As
# votes come in it should go down

trump_RMSE <- pred_results_c %>%
  mutate(trump_pop_vote = trump_pop_vote * 100) %>%
  mutate(sq_error = (trump_pop_vote - trump_pred)^2) %>%
  summarize(RMSE = sqrt(sum(sq_error)))

# very high. Mostly because of Idaho, RH, NY

biden_RMSE <- pred_results_c %>%
  mutate(biden_pop_vote = biden_pop_vote * 100) %>%
  mutate(sq_error = (biden_pop_vote - biden_pred)^2) %>%
  summarize(RMSE = sqrt(sum(sq_error)))

# very high, Mostly because of NY, RI, ND, ID, WV, SD, NE, MT, UT

margin_RMSE <- pred_results_c %>%
  mutate(sq_error = (biden_margin - pred_win_margin)^2) %>%
  summarize(RMSE = sqrt(sum(sq_error)))
