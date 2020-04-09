source("0-hysteresis_packages.R")

relabund = read.csv("data/processed/fticr_relabund.csv")

relabund2 = 
  relabund %>% 
  dplyr::select(texture, treatment, sat_level, Class, relabund) %>% 
  spread(Class, relabund) %>% 
  filter(!treatment=="FM") %>% 
  replace(is.na(.),0)


relabund2$DV = as.matrix(relabund2[,4:12])

# since the relative abundances are not strictly independent and all add to 100 %,
# use the isometric log ratio transformation
# http://www.sthda.com/english/wiki/manova-test-in-r-multivariate-analysis-of-variance#import-your-data-into-r

library(compositions)

man = manova(ilr(clo(DV)) ~ treatment, data = relabund2)
summary(man)

# there is currently an issue with summary(man) becayse residuals have rank 5 < 8
# need to fix

summary.aov(man)
