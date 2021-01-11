## SOIL CARBON-WATER HYSTERESIS
## KAIZAD F. PATEL

## 5f-nmr_stats.R

## THIS SCRIPT CONTAINS CODE TO CALCULATE STATISTICS FOR NMR DATA (RELATIVE ABUNDANCE DATA).

############### #
############### #

source("code/0-hysteresis_packages.R")
library(ggbiplot)



rel_abund = read.csv("data/processed/nmr_rel_abund_cores.csv")
rel_abund_trt = read.csv("data/processed/nmr_rel_abund.csv")

#
# PART II: RELATIVE ABUNDANCE PCA ----

relabund_pca=
  rel_abund %>% 
  ungroup %>% 
  dplyr::select(Core, treatment, sat_level, texture, group, relabund) %>% 
  spread(group, relabund) %>% 
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

ggbiplot(pca, obs.scale = 1, var.scale = 1, 
         groups = relabund_pca_grp$texture, ellipse = TRUE, circle = F,
         var.axes = TRUE)+
  geom_point(size=2,stroke=1, aes(color = groups, shape = relabund_pca_grp$treatment))

#

## 2. separate texture ----
### scl
relabund_pca_scl_num = 
  relabund_pca %>% 
  filter(texture=="SCL") %>% 
  dplyr::select(.,-(1:3))

relabund_pca_scl_grp = 
  relabund_pca %>% 
  filter(texture=="SCL") %>% 
  dplyr::select(.,(1:3)) %>% 
  dplyr::mutate(row = row_number())

pca_scl = prcomp(relabund_pca_scl_num, scale. = T)
summary(pca_scl)

ggbiplot(pca_scl, obs.scale = 1, var.scale = 1, 
         groups = relabund_pca_scl_grp$treatment, ellipse = TRUE, circle = F,
         var.axes = TRUE)+
  geom_point(size=2,stroke=2, aes(color = groups, shape = as.factor(relabund_pca_scl_grp$sat_level)))+
  ggtitle("SCL texture")

### sl
relabund_pca_sl_num = 
  relabund_pca %>% 
  filter(texture=="SL") %>% 
  dplyr::select(.,-(1:3))

relabund_pca_sl_grp = 
  relabund_pca %>% 
  filter(texture=="SL") %>% 
  dplyr::select(.,(1:3)) %>% 
  dplyr::mutate(row = row_number())

pca_sl = prcomp(relabund_pca_sl_num, scale. = T)
summary(pca_sl)

ggbiplot(pca_sl, obs.scale = 1, var.scale = 1, 
         groups = relabund_pca_sl_grp$treatment, ellipse = TRUE, circle = F,
         var.axes = TRUE)+
  geom_point(size=2,stroke=2, aes(color = groups, shape = as.factor(relabund_pca_sl_grp$sat_level)))+
  ggtitle("SL texture")

#
# PART III: summary stats ----
## 1. MANOVA ----

rel_abund2 = 
  rel_abund %>% 
  dplyr::select(Core, texture, treatment, sat_level, group, relabund) %>% 
  spread(group, relabund) %>% 
  replace(is.na(.),0) 

rel_abund2$DV = as.matrix(rel_abund2[,5:9])

# since the relative abundances are not strictly independent and all add to 100 %,
# use the isometric log ratio transformation
# http://www.sthda.com/english/wiki/manova-test-in-r-multivariate-analysis-of-variance#import-your-data-into-r

library(compositions)

man = manova(ilr(clo(DV)) ~ treatment, data = rel_abund2)
summary(man)

#
## 1b. PERMANOVA ----
library(vegan)
adonis2(rel_abund2$DV ~ treatment*sat_level, data = rel_abund2)

#
## 2. relative abundance ANOVA ---- 

fit_aov_nmr <- function(dat) {
  a <-aov(relabund ~ treatment, data = dat)
  tibble(`p` = summary(a)[[1]][[1,"Pr(>F)"]])
} 


nmr_aov = 
  rel_abund %>% 
  filter(!treatment=="FM") %>% 
  #group_by(texture, sat_level, group, treatment) %>% 
  #dplyr::mutate(n = n()) %>% 
  filter(!group %in% c("amide", "alphah")) %>% 
  ungroup %>% 
  group_by(texture, sat_level, group) %>% 
  do(fit_aov_nmr(.)) %>% 
  dplyr::mutate(p = round(p,4),
                asterisk = if_else(p<0.05,"*",as.character(NA)),
                treatment="Wetting") %>% 
  dplyr::select(-p)

nmr_summary = 
  rel_abund_trt %>% 
  left_join(nmr_aov, by = c("texture","sat_level","treatment","group")) %>% 
  dplyr::mutate(
                relabund = paste(relative_abundance, asterisk))

#


# bray distance ----
library(vegan)
library(ape)

bray_distance = vegdist(relabund_pca_num, method="euclidean")
principal_coordinates = pcoa(bray_distance)
pcoa_plot = data.frame(principal_coordinates$vectors[,])
pcoa_plot_merged = merge(pcoa_plot, relabund_pca_grp, by="row.names")

####### Calculate percent variation explained by PC1, PC2

PC1 <- 100*(principal_coordinates$values$Eigenvalues[1]/sum(principal_coordinates$values$Eigenvalues))
PC2 <- 100*(principal_coordinates$values$Eigenvalues[2]/sum(principal_coordinates$values$Eigenvalues))
PC3 <- 100*(principal_coordinates$values$Eigenvalues[3]/sum(principal_coordinates$values$Eigenvalues))


grp = 
  relabund_pca_grp %>% 
  dplyr::mutate(grp = paste0(texture,"-",sat_level,"-",treatment))
  #dplyr::select(row, grp)
matrix = as.matrix(bray_distance)

matrix2 = 
  matrix %>% 
  melt() %>% 
  left_join(grp, by = c("Var1"="row")) %>% 
  #rename(grp1 = grp) %>% 
  left_join(grp, by = c("Var2"="row")) %>% 
  filter(grp.x==grp.y) %>% 
  group_by(grp.x,grp.y,sat_level.x, texture.x,treatment.x,treatment.y) %>% 
  dplyr::summarise(distance  =mean(value)) %>%
  ungroup %>% 
  dplyr::rename(sat_level = sat_level.x) %>% 
  dplyr::mutate(sat_level = if_else(treatment.x=="FM","FM",sat_level),
                sat_level = factor(sat_level, levels = c(5,35,50,75,100,"FM")))


matrix3 = 
  matrix %>% 
  melt() %>% 
  left_join(grp, by = c("Var1"="row")) %>% 
  #rename(grp1 = grp) %>% 
  left_join(grp, by = c("Var2"="row")) %>% 
  filter(!grp.x==grp.y) %>% 
  filter(sat_level.x == sat_level.y) %>% 
  filter(texture.x == texture.y) %>% 
  group_by(grp.x,grp.y,sat_level.x, texture.x,treatment.x,treatment.y) %>% 
  dplyr::summarise(distance  =mean(value)) %>%
  ungroup %>% 
  dplyr::rename(sat_level = sat_level.x) %>% 
  dplyr::mutate(sat_level = factor(sat_level, levels = c(5,35,50,75,100)))

ggplot(matrix3, aes(x = sat_level, y = distance))+
  geom_point(size=3)+
  geom_segment(aes(x = sat_level, xend = sat_level, y = 0, yend = distance))+
  
  facet_grid(.~texture.x)+
  ylim(0,80)+
  ylab("drying-rewetting \n Bray distance")+
  geom_hline(yintercept = 17.52, linetype = "dashed")+
  annotate("text", label = "avg within-group distance", x = 2, y = 15)+
  theme_kp()

ggplot(matrix2, aes(x = sat_level, y = mean(distance), color = treatment.x, shape = texture.x))+
  geom_point(size = 3)+
#  facet_grid(treatment.x.~texture.x)+
  ylim(0,80)+
  theme_kp()
mean(matrix2$distance)
