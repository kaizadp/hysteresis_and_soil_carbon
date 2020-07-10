source("0-hysteresis_packages.R")

relabund = read.csv("data/processed/fticr_relabund.csv")

relabund2 = 
  relabund %>% 
  dplyr::select(texture, treatment, sat_level, Class, relabund) %>% 
  spread(Class, relabund) %>% 
  filter(!treatment=="FM") %>% 
  replace(is.na(.),0)

#
# 1. MANOVA ----
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

#
# 2. PCA ----
# PART II: RELATIVE ABUNDANCE PCA ----

relabund_pca=
  relabund %>% 
  ungroup %>% 
  dplyr::select(Core_assignment, treatment, sat_level, texture, Class, relabund) %>% 
  spread(Class, relabund) %>% 
  replace(.,is.na(.),0)  %>% 
  dplyr::mutate(sat_level = if_else(treatment=="FM","FM", as.character(sat_level))) %>% 
  dplyr::select(-1)

#
## 1. overall PCA ----
relabund_pca_num = 
  relabund_pca %>% 
  dplyr::select(.,-(1:3))

relabund_pca_grp = 
  relabund_pca %>% 
  dplyr::select(.,(1:3)) %>% 
  dplyr::mutate(row = row_number())

pca = prcomp(relabund_pca_num, scale. = T)
summary(pca)

ggbiplot(pca, obs.scale = 1, var.scale = 1, 
         groups = relabund_pca_grp$treatment, ellipse = TRUE, circle = F,
         var.axes = TRUE)+
  geom_point(size=2,stroke=2, aes(color = groups, shape = as.factor(relabund_pca_grp$sat_level)))

