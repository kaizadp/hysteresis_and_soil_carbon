source("0-hysteresis_packages.R")
peaks = read.csv("data/processed/nmr_peaks.csv")

corekey = read.csv(COREKEY)

corekey_subset = 
  corekey %>% 
  dplyr::select(Core, texture, treatment, perc_sat, sat_level,Core_assignment) %>% 
  dplyr::mutate(Core = as.factor(Core))

#
# 1. frequency of peaks ----
peaks2 = 
  peaks %>%
  dplyr::mutate(Core = as.character(Core)) %>% 
# some ppm shifts may have multiple entries
# this is because we are using a precision of only 0.01
# add all these areas together  
  group_by(Core, ppm) %>% 
  dplyr::summarise(Area = sum(Area)) %>% 
  left_join(corekey_subset, by = "Core") %>%
  ungroup %>% 
# now calculate the frequency of peaks within each treatment
  group_by(Core_assignment, texture, sat_level, treatment, ppm) %>% 
  dplyr::summarise(n = n())

## plots
ggplot(peaks2, aes(x = ppm, y = n))+
  geom_point()+
  #geom_segment(aes(x = x, xend = x, y = 0, yend = y))+
  facet_grid(sat_level ~ treatment+texture)
  

source("7a-nmr_spectra_setup.R")
gg_nmr+
  geom_point(data = peaks2, aes(x = ppm, y = n))+
  ylab("frequency")+
  facet_grid(sat_level ~ treatment+texture)

#

# 2. peak assignment ----
# see markdown file

#
