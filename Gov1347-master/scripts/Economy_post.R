#### Economy ####
#### Gov 1347: Election Analysis (2020)
#### TFs: Soubhik Barari, Sun Young Park

####----------------------------------------------------------#
#### Pre-amble ####
####----------------------------------------------------------#

## install via `install.packages("name")`

library(tidyverse)
library(ggplot2)
library(janitor)
popvote_df <- read_csv("Gov1347-master/data/popvote_1948-2016.csv")
economy_df <- read_csv("Gov1347-master/data/econ.csv") 
local_df <- read_csv("Gov1347-master/data/local.csv") %>%
  clean_names() %>%
  filter(!(state_and_area %in% c("New York city", "Los Angeles County"))) %>%
  mutate(month = parse_double(month))

# creating a data set that joins economy and popular vote. Getting rid of candidate column. Filtering for elections after WWII. 

data <- popvote_df %>%
  left_join(economy_df, by = "year") %>%
  filter(year >= 1948, quarter == 2, incumbent_party == TRUE) %>%
  select(year, party, winner, pv2p, incumbent, incumbent_party, prev_admin,
         GDP_growth_qt, GDP_growth_yr, unemployment, stock_close)

vars <- c("GDP_growth_qt")


######## GDP growth qt ###############
######################################

lm_GDP_growth_qt <- lm(pv2p ~ GDP_growth_qt, data = data)

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
              r_sq = r_squared_GDP_growth_qt,
              mse = mse_GDP_growth_qt,
              mean_out = mean_outsamp_GDP_growth_qt)

######## GDP growth yr ###############
######################################

lm_GDP_growth_yr <- lm(pv2p ~ GDP_growth_yr, data = data)

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
              r_sq = r_squared_GDP_growth_yr,
              mse = mse_GDP_growth_yr,
              mean_out = mean_outsamp_GDP_growth_yr)




######## unemployment ###############
######################################

lm_unemployment <- lm(pv2p ~ unemployment, data = data)

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
              r_sq = r_squared_unemployment,
              mse = mse_unemployment,
              mean_out = mean_outsamp_unemployment)


######## stock close ###############
######################################

lm_stock_close <- lm(pv2p ~ stock_close, data = data)

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
              r_sq = r_squared_stock_close,
              mse = mse_stock_close,
              mean_out = mean_outsamp_stock_close)


########## creating stats table #########

Model_Statistics <- Model_Statistics %>%
  rbind(row2, row3, row4)


########## states extension ###############3

local_2 <- local_df %>%
  filter(month %in% c(7, 8, 9)) %>%
  select(state_and_area, year, month, unemployed_prce) %>%
  pivot_wider(names_from = month, values_from = unemployed_prce, names_prefix = "rate_") %>%
  mutate(avg_7_9 = (rate_7 + rate_8 + rate_9)/3)
  


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
