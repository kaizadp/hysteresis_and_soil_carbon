# HYSTERESIS AND SOIL CARBON
# Kaizad F. Patel
# April 2020

# 6c-fticr_loss.R

## this script will compute additional metric for the processed FTICR data.
## this script looks at sequential loss/gain across moisture levels.

############### #
############### #

source("0-hysteresis_packages.R")

# -------------------------------------------------------------------------


fticr_data = read.csv(FTICR_LONG)
fticr_meta = read.csv(FTICR_META)
corekey = read.csv(COREKEY)

# I. determine peaks lost/gained
# everything will be compared to fm soils
# so, first create a separate table for fm soils
# then merge with the DATA file

fticr_fm = 
  fticr_data %>% 
  filter(treatment=="FM") %>% 
  rename(FM = presence) %>% 
  left_join(meta_hcoc, by = "formula")


# SEQUENTIAL LOSS/GAIN FOR WETTING
# SOILS WERE DRIED TO 3% SATURATION AND THEN WET

loss_wetting_3 = 
  fticr_data %>% 
  filter(treatment %in% c("Wetting","FM"),
         perc_sat %in% c(50,3)) %>% 
  dplyr::select(perc_sat, formula,presence) %>% 
  spread(perc_sat, presence) %>% 
  replace(is.na(.),0)  %>% 
  dplyr::mutate(perc_sat = 3,
                treatment = "Wetting") %>% 
  dplyr::mutate(loss = case_when(`50`-`3`==1 ~ "lost",
                                 `3`-`50`==1 ~ "gained",
                                 `3`==1 & `50`==1 ~ "conserved")) %>% 
  dplyr::select(treatment, perc_sat,formula,loss)


loss_wetting_35 = 
  fticr_data %>% 
  filter(treatment %in% c("Wetting"),
         perc_sat %in% c(35,3)) %>% 
  dplyr::select(perc_sat, formula,presence) %>% 
  spread(perc_sat, presence) %>% 
  replace(is.na(.),0)  %>% 
  dplyr::mutate(perc_sat = 35,
                treatment = "Wetting") %>% 
  dplyr::mutate(loss = case_when(`3`-`35`==1 ~ "lost",
                                 `35`-`3`==1 ~ "gained",
                                 `35`==1 & `3`==1 ~ "conserved")) %>% 
  dplyr::select(treatment, perc_sat,formula,loss)


loss_wetting_53 = 
  fticr_data %>% 
  filter(treatment %in% c("Wetting"),
         perc_sat %in% c(53,35)) %>% 
  dplyr::select(perc_sat, formula,presence) %>% 
  spread(perc_sat, presence) %>% 
  replace(is.na(.),0)  %>% 
  dplyr::mutate(perc_sat = 53,
                treatment = "Wetting") %>% 
  dplyr::mutate(loss = case_when(`35`-`53`==1 ~ "lost",
                                 `53`-`35`==1 ~ "gained",
                                 `53`==1 & `35`==1 ~ "conserved")) %>% 
  dplyr::select(treatment, perc_sat,formula,loss)


loss_wetting_100 = 
  fticr_data %>% 
  filter(treatment %in% c("Wetting"),
         perc_sat %in% c(53,100)) %>% 
  dplyr::select(perc_sat, formula,presence) %>% 
  spread(perc_sat, presence) %>% 
  replace(is.na(.),0)  %>% 
  dplyr::mutate(perc_sat = 100,
                treatment = "Wetting") %>% 
  dplyr::mutate(loss = case_when(`53`-`100`==1 ~ "lost",
                                 `100`-`53`==1 ~ "gained",
                                 `100`==1 & `53`==1 ~ "conserved")) %>% 
  dplyr::select(treatment, perc_sat,formula,loss)



fticr_loss_wetting = 
  rbind(loss_wetting_3,
        loss_wetting_35,
        loss_wetting_53,
        loss_wetting_100) %>% 
  left_join(meta_hcoc, by = "formula")
  

gg_vankrev(fticr_loss_wetting[!fticr_loss_wetting$loss=="conserved",], aes(x = OC, y = HC, color = loss))+
             facet_grid(~perc_sat)

gg_vankrev(fticr_fm, aes(x = OC, y = HC))

# SEQUENTIAL LOSS/GAIN FOR DRYING
# SOILS WERE WET TO 100% SATURATION AND THEN DRIED

loss_drying_100 = 
  fticr_data %>% 
  filter(treatment %in% c("Drying","FM"),
         perc_sat %in% c(50,100)) %>% 
  dplyr::select(perc_sat, formula,presence) %>% 
  spread(perc_sat, presence) %>% 
  replace(is.na(.),0)  %>% 
  dplyr::mutate(perc_sat = 100,
                treatment = "Drying") %>% 
  dplyr::mutate(loss = case_when(`50`-`100`==1 ~ "lost",
                                 `100`-`50`==1 ~ "gained",
                                 `100`==1 & `50`==1 ~ "conserved")) %>% 
  dplyr::select(treatment, perc_sat,formula,loss)

loss_drying_53 = 
  fticr_data %>% 
  filter(treatment %in% c("Drying","FM"),
         perc_sat %in% c(53,100)) %>% 
  dplyr::select(perc_sat, formula,presence) %>% 
  spread(perc_sat, presence) %>% 
  replace(is.na(.),0)  %>% 
  dplyr::mutate(perc_sat = 53,
                treatment = "Drying") %>% 
  dplyr::mutate(loss = case_when(`100`-`53`==1 ~ "lost",
                                 `53`-`100`==1 ~ "gained",
                                 `100`==1 & `53`==1 ~ "conserved")) %>% 
  dplyr::select(treatment, perc_sat,formula,loss)

loss_drying_35 = 
  fticr_data %>% 
  filter(treatment %in% c("Drying","FM"),
         perc_sat %in% c(53,35)) %>% 
  dplyr::select(perc_sat, formula,presence) %>% 
  spread(perc_sat, presence) %>% 
  replace(is.na(.),0)  %>% 
  dplyr::mutate(perc_sat = 35,
                treatment = "Drying") %>% 
  dplyr::mutate(loss = case_when(`53`-`35`==1 ~ "lost",
                                 `35`-`53`==1 ~ "gained",
                                 `35`==1 & `53`==1 ~ "conserved")) %>% 
  dplyr::select(treatment, perc_sat,formula,loss)


fticr_loss_drying = 
  rbind(loss_drying_100,
        loss_drying_53,
        loss_drying_35) %>% 
  left_join(meta_hcoc, by = "formula")


fticr_loss_combined = 
  rbind(fticr_loss_drying,
        fticr_loss_wetting)
#

# figures
gg_loss = gg_vankrev(fticr_loss_combined[!fticr_loss_combined$loss=="conserved",], 
                             aes(x = OC, y = HC, color = loss))+
  theme_kp()+
  facet_grid(treatment~perc_sat)

gg_fm = gg_vankrev(fticr_fm, aes(x = OC, y = HC))+
  theme_kp()


library(patchwork)
layout = "
#BC
AB#
"

wrap_plots(A = gg_fm, B = gg_loss, C = gg_fm, design = layout, widths = c(1,5,1))+
  plot_annotation(title = "Sequential loss/gain",
                  caption = "
                  starting with FIELD MOIST
                  DRYING soils were saturated and then dried
                  WETTING soils were dried and then wet.")


gg_fm + gg_loss + gg_fm +
  plot_layout(design = layout)



fticr_loss_temp = 
  fticr_data %>% 
  dplyr::select(Core_assignment, formula, presence) %>% 
  spread(Core_assignment, presence) %>% 
  dplyr::select(-"Soil_fm") %>% 
  melt(id = "formula", variable.name = "Core_assignment", value.name = "presence") %>% 
  left_join(dplyr::select(fticr_fm, formula, FM), by = "formula") %>% 
  dplyr::mutate(presence = replace_na(presence, 0),
                FM = replace_na(FM,0),
                loss = case_when(presence-FM==1 ~ "gained",
                                 FM-presence==1 ~ "lost",
                                 FM==1 & presence==1 ~ "conserved"))  %>% 
  left_join(meta_hcoc, by = "formula") %>% 
  left_join(dplyr::select(corekey,treatment,perc_sat,Core_assignment), by = "Core_assignment")


gg_vankrev(na.omit(fticr_loss_temp),aes(x = OC, y = HC, color = loss))+
  geom_point(size=0.5, alpha=0.1)+
  facet_grid(loss~treatment+perc_sat)
  


######


fticr_loss = 
  fticr_data %>% 
  full_join(dplyr::select(fticr_fm, formula, FM), by = "formula") %>% 
  dplyr::mutate(presence = replace_na(presence,0))


fticr_loss_temp = 
  fticr_data %>% 
  filter(treatment %in% c("Drying","FM"), 
         perc_sat %in% c(100,50)) %>% 
  dplyr::select(treatment, formula,presence) %>% 
  spread(treatment, presence) %>% 
  left_join(meta_hcoc, by = "formula") %>% 
  dplyr::mutate(FM = replace_na(FM,0),
                Drying = replace_na(Drying, 0),
                loss = case_when(FM-Drying == 1 ~ "loss",
                                 Drying-FM == 1 ~ "gained")) %>% 
  na.omit()

gg_vankrev(fticr_loss_temp, aes(x = OC, y = HC, color = loss))+
  ggtitle("100%-drying")
  facet_grid(~loss)


  fticr_data %>% 
    filter(treatment=="FM")
