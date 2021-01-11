## SOIL CARBON-WATER HYSTERESIS
## KAIZAD F. PATEL

## 5b-nmr_peaks_relabund.R

## THIS SCRIPT CONTAINS CODE TO CALCULATE RELATIVE ABUNDANCE BASED ON NMR PEAKS DATA.

############### #
############### #

source("code/5a-nmr_peaks.R")

# first, add metadata for Cores
corekey = read.csv(COREKEY)
key = 
  corekey %>% 
  dplyr::select(Core, treatment, Core_assignment, sat_level, texture) %>% 
  dplyr::mutate(Core = as.character(Core))
  
peaks2 = 
  peaks %>% 
  right_join(key, by = "Core") 
  

rel_abund = 
  subset(merge(peaks2, bins2), start <= ppm & ppm <= stop) %>% 
  #dplyr::select(source,ppm, Area, group) %>% 
  #filter(!(ppm>DMSO_start&ppm<DMSO_stop)) %>% 
  group_by(Core, group, treatment, sat_level, texture) %>% 
  dplyr::summarize(area = sum(Area)) %>% 
  group_by(Core) %>% 
  dplyr::mutate(total = sum(area),
                relabund = round((area/total)*100,2))

#
## ----
# relative abundance by treatment
rel_abund_trt = 
  rel_abund %>% 
  group_by(group, treatment, sat_level, texture, soil_type) %>% 
  dplyr::summarise(rel_abund = round(mean(relabund, na.rm=TRUE),2),
                   se = round(sd(relabund)/sqrt(n()),2)) %>% 
  dplyr::mutate(relative_abundance = paste(rel_abund,"\U00B1",se))


### OUTPUT ----
write.csv(rel_abund_trt, "data/processed/nmr_rel_abund.csv", row.names = FALSE)
write.csv(rel_abund, "data/processed/nmr_rel_abund_cores.csv", row.names = FALSE)
