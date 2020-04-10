source("0-hysteresis_packages.R")
peaks = read.csv("data/processed/nmr_peaks.csv")

corekey = read.csv(COREKEY)

corekey_subset = 
  corekey %>% 
  dplyr::select(Core, texture, treatment, perc_sat, sat_level,Core_assignment) %>% 
  dplyr::mutate(Core = as.factor(Core))


# frequency of peaks ----
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

## peak assignment ----
peak_assg = read.csv("data/nmr_peak_assignments.csv")

p = 
  ggplot()+
  geom_point(data = peak_assg, aes(x = deltaH_ppm, y = 0.5, color = abbrev))+
  geom_text(data = peak_assg, aes(x = deltaH_ppm, y = 0.3, color = abbrev), label = peak_assg$abbrev, angle = 90)+
  geom_text(data = peak_assg, aes(x = deltaH_ppm, y = 0.7, color = abbrev), label = peak_assg$moiety, angle = 90)+
  geom_rect(data=peak_assg, aes(xmin=deltaH_start, xmax=deltaH_stop, 
                                ymin=-Inf, ymax=1.0, fill=abbrev),alpha=0.1)+
  geom_rect(data=bins2, aes(xmin=start, xmax=stop, 
                            ymin=-Inf, ymax=+Inf), fill = "white", color="grey70",alpha=0.1)+
  
  
  ylim(-0.1,1)+
  
  annotate("text", label = "aliphatic", x = 1.4, y = -0.1)+
  annotate("text", label = "O-alkyl", x = 3.5, y = -0.1)+
  annotate("text", label = "alpha-H", x = 4.45, y = -0.1)+
  annotate("text", label = "aromatic", x = 7, y = -0.1)+
  annotate("text", label = "amide", x = 8.1, y = -0.1)
  
  
p + scale_x_reverse(limits = c(2.5,0))
p + scale_x_reverse(limits = c(6,2.5))
p + scale_x_reverse(limits = c(10,6))

  
  
  


  