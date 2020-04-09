# HYSTERESIS AND SOIL CARBON
# 
# Kaizad F. Patel
# April 2020


source("0-hysteresis_packages.R")

# ------------------------------------------------------- ----

# I. LOAD FILES ----

fticr_data = read.csv(FTICR_LONG)
fticr_meta = read.csv(FTICR_META)
meta_hcoc  = read.csv(FTICR_META_HCOC)


# II. RELATIVE ABUNDANCE ----
# add the Class column to the data
corekey_subset = 
  corekey %>% 
  dplyr::select(Core, texture, treatment, perc_sat, sat_level,Core_assignment)
  
relabund = 
  fticr_data %>% 
  left_join(dplyr::select(fticr_meta, formula, Class), by = "formula") %>% 
# create a new column for total counts per core assignment
# since we selected only the peaks seen in all replicates,
# we do not need to calculate rel_abund in each core  
  group_by(Core_assignment, texture, treatment, sat_level, Class) %>% 
  dplyr::summarise(abund = sum(presence)) %>% 
  ungroup %>% 
  group_by(Core_assignment, texture, treatment, sat_level, ) %>% 
  dplyr::mutate(total = sum(abund),
                relabund  = round((abund/total)*100,2))


#
# III. SHANNON DIVERSITY ----
# Shannon diversity, H = - sum [p*ln(p)], where n = no. of individuals per species/total number of individuals

shannon = 
  relabund %>% 
  dplyr::mutate(
                p = abund/total,
                log = log(p),
                p_logp = p*log) %>% 
  group_by(Core_assignment) %>% 
  dplyr::summarize(H1 = sum(p_logp),
                H = round(-1*H1, 2)) %>% 
  dplyr::select(-H1)


#
# IV. OUTPUT ----
write.csv(shannon, "data/processed/fticr_shannon.csv", row.names = FALSE)
write.csv(relabund, "data/processed/fticr_relabund.csv", row.names=FALSE)


