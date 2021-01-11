# HYSTERESIS AND SOIL CARBON
# Kaizad F. Patel
# April 2020

# 6b-fticr_abundance.R

## this script will calculate relative abundance from processed FTICR data.

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
  rename(FM = presence)

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
