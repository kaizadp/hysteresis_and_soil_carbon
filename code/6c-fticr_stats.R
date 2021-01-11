# HYSTERESIS AND SOIL CARBON
# Kaizad F. Patel
# April 2020

## 6c-fticr_stats.R

## use this script to run statistical tests on the processed FTICR data (relative abundances)


############### #
############### #

source("code/0-hysteresis_packages.R")
library(vegan)
library(scales)

# ------------------------------------------------------- ----

# I. load files -----------------------------------------------------------

relabund = read.csv("data/processed/fticr_relabund.csv")

# 1. PERMANOVA ----

## make wider 
relabund2 = 
  relabund %>% 
  dplyr::select(Core, texture, treatment, sat_level, Class, relabund) %>% 
  spread(Class, relabund) %>% 
  filter(!treatment=="FM") %>% 
  filter(texture=="SCL") %>% 
  replace(is.na(.),0)

# create a matrix within relabund2 file, which we will use as the PERMANOVA response variable
relabund2$DV = as.matrix(relabund2[,5:8])

# PERMANOVA
adonis2(relabund2$DV ~ treatment*sat_level, data = relabund2)

#
# PART II: RELATIVE ABUNDANCE PCA ----
relabund_pca=
  relabund %>% 
  ungroup %>% 
  filter(texture=="SCL") %>% 
  #filter(!Core==25) %>% 
  dplyr::select(Core, Core_assignment, treatment, sat_level, texture, Class, relabund) %>% 
  spread(Class, relabund) %>% 
  replace(.,is.na(.),0)  %>% 
  dplyr::mutate(sat_level = if_else(treatment=="FM","FM", as.character(sat_level))) %>% 
  dplyr::select(-1)

#
## 1. overall PCA ----
relabund_pca_num = 
  relabund_pca %>% 
  dplyr::select(.,-(1:4))

relabund_pca_grp = 
  relabund_pca %>% 
  dplyr::select(.,(1:4)) %>% 
  dplyr::mutate(row = row_number())

pca = prcomp(relabund_pca_num, scale. = T)
summary(pca)

ggbiplot(pca, obs.scale = 1, var.scale = 1, 
         groups = relabund_pca_grp$treatment, ellipse = TRUE, circle = F,
         var.axes = TRUE)+
  geom_point(size=2,stroke=2, aes(color = groups, shape = as.factor(relabund_pca_grp$sat_level)))+
  scale_x_continuous(limits = c(-4,4), oob=rescale_none)+
  labs(caption = "core 25 is out of bounds, influenced by aliphatic, ~10 on Axis1")



## 2. relative abundance ANOVA ---- 

fit_aov_nmr <- function(dat) {
  a <-aov(relabund ~ treatment, data = dat)
  tibble(`p` = summary(a)[[1]][[1,"Pr(>F)"]])
} 

fticr_aov = 
  relabund %>% 
  filter(!treatment=="FM" & texture=="SCL") %>% 
  ungroup %>% 
  group_by(texture, sat_level, Class) %>% 
  do(fit_aov_nmr(.)) %>% 
  dplyr::mutate(p = round(p,4),
                asterisk = if_else(p<0.05,"*",as.character(NA)),
                treatment="Wetting") %>% 
  dplyr::select(-p)
