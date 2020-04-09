library(ggbiplot)



rel_abund = read.csv("data/processed/nmr_rel_abund_cores.csv")



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
## 1. overall PCA ---
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
