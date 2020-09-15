#### Economy ####
#### Gov 1347: Election Analysis (2020)
#### TFs: Soubhik Barari, Sun Young Park

####----------------------------------------------------------#
#### Pre-amble ####
####----------------------------------------------------------#

## install via `install.packages("name")`

library(tidyverse)
library(ggplot2)
popvote_df <- read_csv("Gov1347-master/data/popvote_1948-2016.csv")
economy_df <- read_csv("Gov1347-master/data/econ.csv") 

# creating a data set that joins economy and popular vote. Getting rid of candidate column. Filtering for elections after WWII. 

data <- popvote_df %>%
  left_join(economy_df, by = "year") %>%
  filter(year >= 1948, quarter == 2, incumbent_party == TRUE) %>%
  select(year, party, winner, pv2p, incumbent, incumbent_party, prev_admin,
         GDP_growth_qt, GDP_growth_yr, unemployment, stock_open)

vars <- c("GDP_growth_qt")


######## GDP growth qt ###############
######################################

lm_GDP_growth_qt <- lm(pv2p ~ GDP_growth_qt, data = data)

# checking in sample model error and MSE

r_squared <- summary(lm_GDP_growth_qt)$r.squared

mse <- sqrt(mean((lm_GDP_growth_qt$model$pv2p - lm_GDP_growth_qt$fitted.values)^2))

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

mean_outsamp <- mean(abs(outsamp_errors))

row1 <- table(var = "GDP_growth_qt",
              r_sq = r_squared,
              mse = mse,
              mean_out = mean_outsamp)


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

for(i in )



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
