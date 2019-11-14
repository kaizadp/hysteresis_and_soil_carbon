## 3b-Picarro graphs


source("0-hysteresis_packages.R")
source("1-moisture_tracking.R")
source("3-picarro_data.R")

#devtools::install_github("jakelawlor/PNWColors") 
#library(PNWColors)

library(drake)

plan <- drake_plan(
  # Metadata
  core_key = read_core_key(file_in("data/Core_key.xlsx")) %>% 
    filter(is.na(skip)) %>% 
    dplyr::mutate(Moisture = dplyr::recode(Moisture,
                                           "100.0"="100",
                                           "75.0"="75",
                                           "50.0"="50")) %>% 
    dplyr::mutate(Status = case_when(grepl("_D$", Core_assignment) ~ "Dry",
                                     grepl("_W$", Core_assignment) ~ "Wet",
                                     grepl("_fm$", Core_assignment) ~ "FM"),
                  moisture_lvl = if_else(soil_type=="Soil"&Moisture=="sat","140",
                                         if_else(soil_type=="Soil_sand"&Moisture=="sat","100",
                                                 if_else(Moisture=="dry","5",
                                                         if_else(soil_type=="Soil_sand"&Moisture=="100","40",as.character((Moisture))))))) %>% 
    dplyr::mutate(moisture_lvl = factor(moisture_lvl, levels = c("140","100","75","50","40","5","fm"))),
  
  core_dry_weights = read_core_dryweights(file_in("data/Core_weights.xlsx"), sheet = "initial"),
  core_masses = read_core_masses(file_in("data/Core_weights.xlsx"),
                                 sheet = "Mass_tracking", core_key, core_dry_weights),
  valve_key = filter(core_masses, Seq.Program == "CPCRW_SFDec2018.seq"),
  
  # Picarro data
  # Using the 'trigger' argument below means we only re-read the Picarro raw
  # data when necessary, i.e. when the files change
  picarro_raw = target(process_directory("data/picarro_data/"),
                       trigger = trigger(change = list.files("data/picarro_data/", pattern = "dat$", recursive = TRUE))),
  picarro_clean = clean_picarro_data(picarro_raw),
  
  # Match Picarro data with the valve key data
  pcm = match_picarro_data(picarro_clean, valve_key),
  picarro_clean_matched = pcm$pd,
  picarro_match_count = pcm$pmc,
  valve_key_match_count = pcm$vkmc,
  
  qc1 = qc_match(picarro_clean, picarro_clean_matched, valve_key, picarro_match_count, valve_key_match_count),
  qc2 = qc_concentrations(picarro_clean_matched, valve_key),
  
  ghg_fluxes = compute_ghg_fluxes(picarro_clean_matched, valve_key),
  qc3 = qc_fluxes(ghg_fluxes, valve_key),
  
#summarizing  
ghg_fluxes %>%
    group_by(Core) %>% 
    dplyr::summarise(cum = sum(flux_co2_umol_g_s),
                     max = max(flux_co2_umol_g_s),
                     mean = mean(flux_co2_umol_g_s),
                     sd = sd(flux_co2_umol_g_s),
                     se = sd/sqrt(n()),
                     n = n()) %>% 
    left_join(core_key, by = "Core")-> cum_flux,
  
cum_flux %>% 
    group_by(soil_type,moisture_lvl,trt) %>% 
    dplyr::summarize(cum = mean(cum),
                     max = mean(max))->mean,  
  
  
  
# preliminary plots

p_cum = ggplot(cum_flux, aes(x = moisture_lvl, y = cum*1000, color = trt))+
  geom_point(position = position_dodge(width = 0.5))+
  geom_smooth(data = mean, aes(x = as.numeric(moisture_lvl), y = cum*1000))+
  geom_vline(xintercept = 6.5)+
  ylab("cum flux_co2_nmol_g_s")+
  facet_grid(soil_type~.)+
  ggtitle("cumulative CO2 flux"),

p_max = ggplot(cum_flux, aes(x = moisture_lvl, y = max*1000, color = trt))+
  geom_point(position = position_dodge(width = 0.5))+
  geom_smooth(data = mean, aes(x = as.numeric(moisture_lvl), y = max*1000))+
  geom_vline(xintercept = 6.5)+
  ylab("maximum flux_co2_nmol_g_s")+
  facet_grid(soil_type~.)+
  ggtitle("maximum CO2 flux"),

p_num = ggplot(cum_flux, aes(x = Core, y = n))+
  geom_point()+
  ggtitle("no. of readings"),

p_cores = ggplot(gf, aes(DATETIME, flux_co2_umol_g_s*1000, color = Sand)) + 
  geom_point() + geom_line() +
  ylab("flux_co2_nmol_g_s")+
  facet_wrap(~Core, scale = "free_x")+
  geom_hline(yintercept = 0)+
  theme(legend.position="none"),

p_trt = ggplot(gf, aes(DATETIME, flux_co2_umol_g_s*1000, color = Core_assignment)) + 
  geom_point() + geom_line() +
  ylab("flux_co2_nmol_g_s")+
  facet_wrap(~Core_assignment, scale = "free_x")+
  geom_hline(yintercept = 0)+
  theme(legend.position="none"),
  
  
  
ggsave("outputs/fluxes_co2_cum.png", plot = p_cum, width = 8, height = 6),
ggsave("outputs/fluxes_co2_max.png", plot = p_max, width = 8, height = 6),
ggsave("outputs/fluxes_co2_count.png", plot = p_num, width = 8, height = 6),
ggsave("outputs/fluxes_co2_cores.png", plot = p_cores, width = 10, height = 10),
ggsave("outputs/fluxes_co2_trt.png", plot = p_trt, width = 15, height = 15)

)
message("Now type make(plan)")


### data analysis
core_key = readd(core_key) %>% filter(is.na(skip)) %>% 
  dplyr::mutate(Moisture = dplyr::recode(Moisture,
                                  "100.0"="100",
                                  "75.0"="75",
                                  "50.0"="50"),
                trt = dplyr::recode(trt,
                                  "D"="drying",
                                  "W"="wetting")) %>% 
  dplyr::mutate(Status = case_when(grepl("_D$", Core_assignment) ~ "Dry",
                                   grepl("_W$", Core_assignment) ~ "Wet",
                                   grepl("_fm$", Core_assignment) ~ "FM"),
                moisture_lvl = if_else(soil_type=="Soil"&Moisture=="sat","140",
                                       if_else(soil_type=="Soil_sand"&Moisture=="sat","100",
                                               if_else(Moisture=="dry","5",
                                                       if_else(soil_type=="Soil_sand"&Moisture=="100","40",as.character((Moisture))))))) %>% 
  dplyr::mutate(moisture_lvl = factor(moisture_lvl, levels = c("140","100","75","50","40","5","fm")))

ghg_fluxes = readd(ghg_fluxes) 

# calculating cumulative flux
ghg_fluxes %>%
  group_by(Core) %>% 
  dplyr::summarise(cum = sum(flux_co2_umol_g_s),
                   max = max(flux_co2_umol_g_s),
                   mean = mean(flux_co2_umol_g_s),
                   sd = sd(flux_co2_umol_g_s),
                   se = sd/sqrt(n()),
                   n = n()) %>% 
  left_join(core_key, by = "Core")-> cum_flux


cum_flux %>% 
  group_by(soil_type,moisture_lvl,trt) %>% 
  dplyr::summarize(cum = mean(cum),
                   max = mean(max))->mean

# plot of cumulative flux
ggplot(cum_flux, aes(x = moisture_lvl, y = cum*1000, color = trt))+
  geom_point(position = position_dodge(width = 0.5))+
 # geom_path(data = mean, aes(x = as.numeric(moisture_lvl), y = cum*1000),position = position_dodge(width = 0.5))+
  geom_smooth(data = mean, aes(x = as.numeric(moisture_lvl), y = cum*1000))+
#  geom_boxplot(position = position_dodge(width = 0.5), fill = NA, width = 0.5)+
  geom_vline(xintercept = 6.5)+
  ylab("cum flux_co2_nmol_g_s")+
#  scale_color_manual(values = pnw_palette("Bay",n=3))+
  facet_grid(soil_type~.)+
  ggtitle("cumulative CO2 flux")+
  theme_kp()

# plot of maximum flux
ggplot(cum_flux, aes(x = moisture_lvl, y = max*1000, color = trt))+
  geom_point(position = position_dodge(width = 0.5))+
  geom_smooth(data = mean, aes(x = as.numeric(moisture_lvl), y = max*1000))+
  #  geom_boxplot(position = position_dodge(width = 0.5), fill = NA, width = 0.5)+
  geom_vline(xintercept = 6.5)+
  ylab("maximum flux_co2_nmol_g_s")+
  #  scale_color_manual(values = pnw_palette("Bay",n=3))+
  facet_grid(soil_type~.)+
  ggtitle("maximum CO2 flux")+
  theme_kp()

# number of readings
ggplot(cum_flux, aes(x = Core, y = n))+
  geom_point()+
  ggtitle("no. of readings")
  

ghg_fluxes %>% group_by(Core) %>% 
  dplyr::mutate(Hours = as.integer(difftime(DATETIME, min(DATETIME), units = "hours"))) %>% 
  group_by(Core) %>% dplyr::summarise(MaxHours = max(Hours))->
  fluxes_time

# length of Picarro measurements
ggplot(fluxes_time, aes(x = Core, y = MaxHours))+
  geom_point()+
  ylab ("hours")+
  ggtitle("length of Picarro readings")

  
gf = readd(gf)

ggplot(gf, aes(DATETIME, flux_co2_umol_g_s*1000, color = Sand)) + 
  geom_point() + geom_line() +
  ylab("flux_co2_nmol_g_s")+
  facet_wrap(~Core, scale = "free_x")+
  geom_hline(yintercept = 0)+
  theme(legend.position="none")

