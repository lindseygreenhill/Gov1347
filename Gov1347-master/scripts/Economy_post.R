#### Economy ####
#### Gov 1347: Election Analysis (2020)
#### TFs: Soubhik Barari, Sun Young Park

####----------------------------------------------------------#
#### Pre-amble ####
####----------------------------------------------------------#

## install via `install.packages("name")`

library(tidyverse)
library(ggplot2)
library(rsample)
library(janitor)
library(gt)
popvote_df <- read_csv("Gov1347-master/data/popvote_1948-2016.csv")
economy_df <- read_csv("Gov1347-master/data/econ.csv") 
local_df <- read_csv("Gov1347-master/data/local.csv") %>%
  clean_names() %>%
  filter(!(state_and_area %in% c("New York city", "Los Angeles County"))) %>%
  mutate(month = parse_double(month))

popvote_state <- read_csv("Gov1347-master/data/popvote_bystate_1948-2016.csv")

# creating a data set that joins economy and popular vote. Getting rid of candidate column. Filtering for elections after WWII. 

data <- popvote_df %>%
  left_join(economy_df, by = "year") %>%
  filter(year >= 1948, quarter == 2, incumbent_party == TRUE) %>%
  select(year, party, winner, pv2p, incumbent, incumbent_party, prev_admin,
         GDP_growth_qt, GDP_growth_yr, unemployment, stock_close, RDI_growth)

# getting rid of scientific notation
options(scipen = 999)



######## GDP growth qt ###############
######################################

cor_GDP_growth_qt <- cor(data$GDP_growth_qt, data$pv2p)

lm_GDP_growth_qt <- lm(pv2p ~ GDP_growth_qt, data = data)

estimate_GDP_growth_qt <- lm_GDP_growth_qt %>% tidy() %>%
  filter(term == "GDP_growth_qt") %>% pull(estimate)

# checking in sample model error and MSE

r_squared_GDP_growth_qt<- summary(lm_GDP_growth_qt)$r.squared

mse_GDP_growth_qt <- sqrt(mean((lm_GDP_growth_qt$model$pv2p - lm_GDP_growth_qt$fitted.values)^2))

## model testing: cross-validation (1000 runs)

outsamp_errors <- sapply(1:1000, function(i){
  years_outsamp <- sample(data$year, 8)
  outsamp_mod <- lm(pv2p ~ GDP_growth_qt,
                    data[!(data$year %in% years_outsamp),])
  outsamp_pred <- predict(outsamp_mod,
                          newdata = data[data$year %in% years_outsamp,])
  outsamp_true <- data$pv2p[data$year %in% years_outsamp]
  mean(outsamp_pred - outsamp_true)
})

mean_outsamp_GDP_growth_qt <- mean(abs(outsamp_errors))

Model_Statistics <- tibble(var = "GDP_growth_qt",
              cor = cor_GDP_growth_qt,
              estimate = estimate_GDP_growth_qt,
              r_sq = r_squared_GDP_growth_qt,
              mse = mse_GDP_growth_qt,
              mean_out = mean_outsamp_GDP_growth_qt)

######## GDP growth yr ###############
######################################

cor_GDP_growth_yr <- cor(data$GDP_growth_yr, data$pv2p)


lm_GDP_growth_yr <- lm(pv2p ~ GDP_growth_yr, data = data)

estimate_GDP_growth_yr <- lm_GDP_growth_yr %>% tidy() %>%
  filter(term == "GDP_growth_yr") %>% pull(estimate)
# checking in sample model error and MSE

r_squared_GDP_growth_yr<- summary(lm_GDP_growth_yr)$r.squared

mse_GDP_growth_yr <- sqrt(mean((lm_GDP_growth_yr$model$pv2p - lm_GDP_growth_yr$fitted.values)^2))

## model testing: cross-validation (1000 runs)

outsamp_errors <- sapply(1:1000, function(i){
  years_outsamp <- sample(data$year, 8)
  outsamp_mod <- lm(pv2p ~ GDP_growth_yr,
                    data[!(data$year %in% years_outsamp),])
  outsamp_pred <- predict(outsamp_mod,
                          newdata = data[data$year %in% years_outsamp,])
  outsamp_true <- data$pv2p[data$year %in% years_outsamp]
  mean(outsamp_pred - outsamp_true)
})

mean_outsamp_GDP_growth_yr <- mean(abs(outsamp_errors))

row3 <- c(var = "GDP_growth_yr",
          cor = cor_GDP_growth_yr,
          estimate = estimate_GDP_growth_yr,
              r_sq = r_squared_GDP_growth_yr,
              mse = mse_GDP_growth_yr,
              mean_out = mean_outsamp_GDP_growth_yr)




######## unemployment ###############
######################################

cor_unemployment <- cor(data$unemployment, data$pv2p)

lm_unemployment <- lm(pv2p ~ unemployment, data = data)

estimate_unemployment <- lm_unemployment %>% tidy() %>%
  filter(term == "unemployment") %>% pull(estimate)

# checking in sample model error and MSE

r_squared_unemployment <- summary(lm_unemployment)$r.squared

mse_unemployment <- sqrt(mean((lm_unemployment$model$pv2p - lm_unemployment$fitted.values)^2))

## model testing: cross-validation (1000 runs)

outsamp_errors <- sapply(1:1000, function(i){
  years_outsamp <- sample(data$year, 8)
  outsamp_mod <- lm(pv2p ~ unemployment,
                    data[!(data$year %in% years_outsamp),])
  outsamp_pred <- predict(outsamp_mod,
                          newdata = data[data$year %in% years_outsamp,])
  outsamp_true <- data$pv2p[data$year %in% years_outsamp]
  mean(outsamp_pred - outsamp_true)
})

mean_outsamp_unemployment <- mean(abs(outsamp_errors))

row2 <- c(var = "unemployment",
          cor = cor_unemployment,
          estimate = estimate_unemployment,
              r_sq = r_squared_unemployment,
              mse = mse_unemployment,
              mean_out = mean_outsamp_unemployment)


######## stock close ###############
######################################

cor_stock_close <- cor(data$stock_close, data$pv2p)

lm_stock_close <- lm(pv2p ~ stock_close, data = data)

estimate_stock_close <- lm_stock_close %>% tidy() %>%
  filter(term == "stock_close") %>% pull(estimate)

# checking in sample model error and MSE

r_squared_stock_close <- summary(lm_stock_close)$r.squared

mse_stock_close <- sqrt(mean((lm_stock_close$model$pv2p - lm_stock_close$fitted.values)^2))

## model testing: cross-validation (1000 runs)

outsamp_errors <- sapply(1:1000, function(i){
  years_outsamp <- sample(data$year, 8)
  outsamp_mod <- lm(pv2p ~ stock_close,
                    data[!(data$year %in% years_outsamp),])
  outsamp_pred <- predict(outsamp_mod,
                          newdata = data[data$year %in% years_outsamp,])
  outsamp_true <- data$pv2p[data$year %in% years_outsamp]
  mean(outsamp_pred - outsamp_true)
})

mean_outsamp_stock_close <- mean(abs(outsamp_errors))

row4 <- c(var = "stock_close",
          cor = cor_stock_close,
          estimate = estimate_stock_close,
              r_sq = r_squared_stock_close,
              mse = mse_stock_close,
              mean_out = mean_outsamp_stock_close)


######## RDI growth ###############
######################################



data_RDI <- data %>% filter(year >= 1960)
cor_RDI_growth <- cor(data_RDI$RDI_growth, data_RDI$pv2p)

lm_RDI_growth <- lm(pv2p ~ RDI_growth, data = data_RDI)

estimate_RDI_growth <- lm_RDI_growth %>% tidy() %>%
  filter(term == "RDI_growth") %>% pull(estimate)

# checking in sample model error and MSE

r_squared_RDI_growth <- summary(lm_RDI_growth)$r.squared

mse_RDI_growth <- sqrt(mean((lm_RDI_growth$model$pv2p - lm_RDI_growth$fitted.values)^2))

## model testing: cross-validation (1000 runs)

outsamp_errors <- sapply(1:1000, function(i){
  years_outsamp <- sample(data_RDI$year, 8)
  outsamp_mod <- lm(pv2p ~ RDI_growth,
                    data_RDI[!(data_RDI$year %in% years_outsamp),])
  outsamp_pred <- predict(outsamp_mod,
                          newdata = data_RDI[data_RDI$year %in% years_outsamp,])
  outsamp_true <- data_RDI$pv2p[data_RDI$year %in% years_outsamp]
  mean(outsamp_pred - outsamp_true)
})

mean_outsamp_RDI_growth <- mean(abs(outsamp_errors))

row5 <- c(var = "RDI_growth",
          cor = cor_RDI_growth,
          estimate  = estimate_RDI_growth,
          r_sq = r_squared_RDI_growth,
          mse = mse_RDI_growth,
          mean_out = mean_outsamp_RDI_growth)


########## creating stats table #########

Model_Statistics <- Model_Statistics %>%
  rbind(row2, row3, row4, row5)

Model_Stats <- Model_Statistics %>%
  mutate(Correlation = parse_number(cor),
         Estimate =  parse_number(estimate),
         R_Sq = parse_number(r_sq),
         MSE = parse_number(mse),
         Outsampling_Error = parse_number(mean_out)
         ) %>%
  mutate_if(is.numeric, round, digits = 3)  %>%
  select(-(2:6)) %>%
  arrange(desc(R_Sq))

stats_gt <- Model_Stats %>%
  gt() %>%
  tab_header(title = "Linear Regression Results") %>%
  cols_label(var = "IV",  R_Sq = "R Sq",
             Outsampling_Error = "Outsampling Error")

########## Predictions ##########

GDP_new <- economy_df %>%
  filter(year == 2020, quarter == 2)  %>%
  select(GDP_growth_qt)

GDP_prediction  <- predict(lm_GDP_growth_qt, GDP_new, interval="prediction")

RDI_new <- economy_df %>%
  filter(year == 2020, quarter == 1)  %>%
  select(RDI_growth)

RDI_prediction  <- predict(lm_RDI_growth, RDI_new, interval="prediction")


GDP_yr_new <- economy_df %>%
  filter(year == 2020, quarter == 1)  %>%
  select(GDP_growth_yr)

GDP_yr_prediction  <- predict(lm_GDP_growth_yr, GDP_yr_new, interval="prediction")


########## NYT Graph ##########

Extrap_GDP <- economy_df %>%
  filter(year >= 1948,  quarter %in%  c(1,2)) %>%
  mutate(quarter = if_else(quarter== 1, "Q1","Q2")) %>%
  ggplot(aes(x = year, y = GDP_growth_qt, fill = (GDP_growth_qt > 0))) +
  facet_wrap(~quarter) +
  geom_col(show.legend = FALSE) + 
  theme_classic() +
  labs(title = "Quarterly GDP Growth 1948-2020",
       subtitle = "2020 Q2 GDP decline is unprecedented",
       x = "Year",
       y = "Quarterly GDP Growth")

######### Q1 GDP ##########
data_q1 <- popvote_df %>%
  left_join(economy_df, by = "year") %>%
  filter(year >= 1948, quarter == 1, incumbent_party == TRUE) %>%
  select(year, party, winner, pv2p, incumbent, incumbent_party, prev_admin,
         GDP_growth_qt, GDP_growth_yr, unemployment, stock_close, RDI_growth)



######## GDP growth qt ###############
######################################

cor_GDP_growth_qt_1 <- cor(data_q1$GDP_growth_qt, data_q1$pv2p)

lm_GDP_growth_qt_1 <- lm(pv2p ~ GDP_growth_qt, data = data)

estimate_GDP_growth_qt_1 <- lm_GDP_growth_qt_1 %>% tidy() %>%
  filter(term == "GDP_growth_qt") %>% pull(estimate)

# checking in sample model error and MSE

r_squared_GDP_growth_qt_1<- summary(lm_GDP_growth_qt_1)$r.squared

mse_GDP_growth_qt_1 <- sqrt(mean((lm_GDP_growth_qt_1$model$pv2p - lm_GDP_growth_qt_1$fitted.values)^2))

## model testing: cross-validation (1000 runs)

outsamp_errors <- sapply(1:1000, function(i){
  years_outsamp <- sample(data_q1$year, 8)
  outsamp_mod <- lm(pv2p ~ GDP_growth_qt,
                    data_q1[!(data_q1$year %in% years_outsamp),])
  outsamp_pred <- predict(outsamp_mod,
                          newdata = data_q1[data_q1$year %in% years_outsamp,])
  outsamp_true <- data_q1$pv2p[data_q1$year %in% years_outsamp]
  mean(outsamp_pred - outsamp_true)
})

mean_outsamp_GDP_growth_qt_1 <- mean(abs(outsamp_errors))

Model_Statistics_1 <- tibble(var = "GDP_growth_qt_1",
                           cor = cor_GDP_growth_qt_1,
                           estimate = estimate_GDP_growth_qt_1,
                           r_sq = r_squared_GDP_growth_qt_1,
                           mse = mse_GDP_growth_qt_1,
                           mean_out = mean_outsamp_GDP_growth_qt_1)

## prediction q1 ######

GDP_new_1 <- economy_df %>%
  filter(year == 2020, quarter == 1)  %>%
  select(GDP_growth_qt)

GDP_prediction_1  <- predict(lm_GDP_growth_qt_1, GDP_new_1, interval="prediction")






########## states extension ###############3

data_state <- data %>%
  select(year, party)

local_2 <- local_df %>%
  filter(month %in% c(7, 8, 9), (year%%4) == 0) %>%
  select(state_and_area, year, month, unemployed_prce) %>%
  pivot_wider(names_from = month, values_from = unemployed_prce, names_prefix = "rate_") %>%
  mutate(avg_7_9 = (rate_7 + rate_8 + rate_9)/3)

local_vote <- local_2 %>%
  left_join(popvote_state, by = c("state_and_area" = "state", "year")) %>%
  left_join(data_state, by = "year") %>%
  mutate(incumbent_vs = if_else(party == "republican", R_pv2p,  D_pv2p))

states <- c("Arizona", "Colorado", "Florida", "Georgia", "Iowa", "Maine", "Michigan",
            "North Carolina", "Ohio", "Pennsyvania")

local_vote %>%
  ggplot(aes(avg_7_9, incumbent_vs)) +
  geom_point() +
  geom_smooth(method = "lm")
  

correlations <- data_frame()
for(i in unique(local_vote$state_and_area)){
  df <- local_vote  %>%
    filter(state_and_area == i)
  
  cor <- cor(df$avg_7_9, df$incumbent_vs)
  
  vector <- data.frame(state = i, correlation = cor)
  
  # binding vector with forcasts
  
  correlations <- correlations %>% bind_rows(vector)

}

# means that this model could be a powerful way to predict some states but not
# others. probably better off sticking with normal economy but this could be
# interesting to look at for some  states such as Texas, Mississippi
  


# loop attemp


for(i in vars){
  
 lm_x <- lm(pv2p ~ data[[i]], data = data)
 
# checking in sample model error and MSE
 
 r_squared <- summary(lm_x)$r.squared
 
 mse <- sqrt(mean((lm_x$model$pv2p - lm_x$fitted.values)^2))
 
 ## model testing: cross-validation (1000 runs)
 
 outsamp_errors <- sapply(1:1000, function(j){
   years_outsamp <- sample(data$year, 8)
   outsamp_mod <- lm(pv2p ~ data[[i]],
                     data[!(data$year %in% years_outsamp),])
   outsamp_pred <- predict(outsamp_mod,
                           newdata = data[data$year %in% years_outsamp,])
   outsamp_true <- data$pv2p[data$year %in% years_outsamp]
   mean(outsamp_pred - outsamp_true)
 })
 
 mean_outsamp <- mean(abs(outsamp_errors))
# 
# row1 <- table(var = i,
#               r_sq = r_squared,
#               mse = mse,
#               mean_out = mean_outsamp)
}

# cross 




# # creating a loop to test different models
# 
# for(i in IV){
#   
#   var <- i
#   print(var)
#   
#   # fitting a model
#   
#    lm_x <- lm(pv2p ~ i, data = data, drop.unused.levels = FALSE)
#   # 
#   # # getting in sample error and MSE
#   # 
#    r_squared <- summary(lm_x)$r.squared
#   # 
#    mse <- sqrt(mean((lm_x$model$pv2p - lm_x$fitted.values)^2))
# 
# }

# fitting a model



## scatterplot + line
dat %>%
  ggplot(aes(x=GDP_growth1, y=voteshare,
             label=year)) + 
  geom_text() +
  geom_smooth(method="lm", formula = y ~ x) +
  geom_hline(yintercept=50, lty=2) +
  geom_vline(xintercept=0.01, lty=2) + # median
  xlab("Second quarter GDP growth") +
  ylab("Incumbent party's national popular voteshare") +
  theme_bw()

## fit a model

lm_econ <- lm(pv2p ~ GDP_growth_qt, data = dat)

# getting in sample error and MSE

summary(lm_econ)

dat %>%
  ggplot(aes(x=GDP_growth_qt, y=pv2p,
             label=year)) + 
    geom_text(size = 8) +
    geom_smooth(method="lm", formula = y ~ x) +
    geom_hline(yintercept=50, lty=2) +
    geom_vline(xintercept=0.01, lty=2) + # median
    xlab("Q2 GDP growth (X)") +
    ylab("Incumbent party PV (Y)") +
    theme_bw() +
    ggtitle("Y = 49.44 + 2.969 * X") + 
    theme(axis.text = element_text(size = 20),
          axis.title = element_text(size = 24),
          plot.title = element_text(size = 32))

## model fit 

#TODO

## model testing: leave-one-out
outsamp_mod  <- lm(pv2p ~ GDP_growth_qt, dat[dat$year != 2016,])
outsamp_pred <- predict(outsamp_mod, dat[dat$year == 2016,])
outsamp_true <- dat$pv2p[dat$year == 2016] 

## model testing: cross-validation (one run)
years_outsamp <- sample(dat$year, 8)
mod <- lm(pv2p ~ GDP_growth_qt,
          dat[!(dat$year %in% years_outsamp),])

outsamp_pred <- #TODO
  
## model testing: cross-validation (1000 runs)
outsamp_errors <- sapply(1:1000, function(i){
  years_outsamp <- sample(data$year, 8)
  outsamp_mod <- lm(pv2p ~ GDP_growth_qt,
                    data[!(data$year %in% years_outsamp),])
  outsamp_pred <- predict(outsamp_mod,
                          newdata = data[data$year %in% years_outsamp,])
  outsamp_true <- data$pv2p[data$year %in% years_outsamp]
  mean(outsamp_pred - outsamp_true)
})

hist(outsamp_errors,
     xlab = "",
     main = "mean out-of-sample residual\n(1000 runs of cross-validation)")

## prediction for 2020
GDP_new <- economy_df %>%
    subset(year == 2020 & quarter == 2) %>%
    select(GDP_growth_qt)

predict(lm_econ, GDP_new)

#TODO: predict uncertainty
  
## extrapolation?
##   replication of: https://nyti.ms/3jWdfjp

economy_df %>%
  subset(quarter == 2 & !is.na(GDP_growth1)) %>%
  ggplot(aes(x=year, y=GDP_growth1,
             fill = (GDP_growth1 > 0))) +
  geom_col() +
  xlab("Year") +
  ylab("GDP Growth (Second Quarter)") +
  ggtitle("The percentage decrease in G.D.P. is by far the biggest on record.") +
  theme_bw() +
  theme(legend.position="none",
        plot.title = element_text(size = 12,
                                  hjust = 0.5,
                                  face="bold"))

