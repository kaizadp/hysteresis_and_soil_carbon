# HYSTERESIS AND SOIL CARBON
# Kaizad F. Patel
# April 2020

# 6b-fticr_abundance.R

## this script will calculate relative abundance from processed FTICR data.

############### #
############### #

source("code/0-hysteresis_packages.R")

# ------------------------------------------------------- ----

# I. LOAD FILES ----

fticr_data = read.csv(FTICR_LONG)
fticr_meta = read.csv(FTICR_META)
meta_hcoc  = read.csv(FTICR_META_HCOC)
corekey = read.csv(COREKEY)

# II. RELATIVE ABUNDANCE ----
# add the Class column to the data
corekey_subset = 
  corekey %>% 
  dplyr::select(Core, texture, treatment, perc_sat, sat_level,Core_assignment)


## IIa. calculate relative abundance per core ----  
relabund_core = 
  fticr_data %>% 
  left_join(dplyr::select(fticr_meta, formula, Class), by = "formula") %>% 
# create a new column for total counts per core assignment
# since we selected only the peaks seen in all replicates,
# we do not need to calculate rel_abund in each core  
  group_by(Core, Core_assignment, texture, treatment, sat_level, Class) %>% 
  dplyr::summarise(abund = sum(presence)) %>% 
  ungroup %>% 
  group_by(Core, Core_assignment, texture, treatment, sat_level, ) %>% 
  dplyr::mutate(total = sum(abund),
                relabund  = round((abund/total)*100,2))


## IIb. calculate relative abundance per treatment ----  
relabund_trt = 
  relabund_core %>% 
  group_by(Core_assignment, texture, treatment, sat_level, Class) %>% 
  dplyr::summarise(rel_abund = round(mean(relabund),2))

#
# IV. OUTPUT ----
write.csv(relabund_core, "data/processed/fticr_relabund.csv", row.names=FALSE)
write.csv(relabund_trt, "data/processed/fticr_relabund_trt.csv", row.names=FALSE)


