## SOIL CARBON-WATER HYSTERESIS
## KAIZAD F. PATEL

## 3b-picarro_output.R

## THIS SCRIPT CONTAINS THE {DRAKE} PLAN TO RUN AND PROCESS PICARRO FUNCTIONS.

############### #
############### #

source("code/0-hysteresis_packages.R")
source("code/1-moisture_tracking.R")
source("code/3a-picarro_data.R")

#devtools::install_github("jakelawlor/PNWColors") 
#library(PNWColors)

plan <- drake_plan(
  
  core_key = read_core_key(file_in(COREKEY)), 
  corekey_subset = core_key %>% dplyr::select(Core, Core_assignment, texture, treatment, sat_level),
  
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
  
  gf = 
    ghg_fluxes %>% 
    left_join(dplyr::select(valve_key, Core, Core_assignment), by = "Core") %>% 
    # mutate(Sand = if_else(grepl("sand", Core_assignment), "Soil_sand", "Soil"),
    #        Status = case_when(grepl("_D$", Core_assignment) ~ "Dry",
    #                           grepl("_W$", Core_assignment) ~ "Wet",
    #                           grepl("_fm$", Core_assignment) ~ "FM")) %>% 
    filter(flux_co2_umol_g_s>=0) %>% 
    #  left_join(select(core_key, Core,sat_level,treatment),by = "Core") %>% 
    # flag outliers
    group_by(Core_assignment) %>% 
    dplyr::mutate(mean = mean(flux_co2_umol_g_s),
                  median = median(flux_co2_umol_g_s),
                  sd = sd(flux_co2_umol_g_s)) %>% 
    ungroup %>% 
    dplyr::mutate(outlier = ((flux_co2_umol_g_s - mean) > 4*sd)),
  
  # remove outliers and unnecessary columns
  gf_clean = 
    gf %>% 
    filter(outlier==FALSE) %>% 
    dplyr::select(1:8),
  
  gf_nm  = 
    gf_clean %>% 
    dplyr::mutate(flux_co2_nmol_g_s = flux_co2_umol_g_s*1000,
                  flux_co2_nmol_gC_s = flux_co2_umol_gC_s*1000) ,
  gf_core = 
    gf_nm %>% 
    group_by(Core) %>% 
    dplyr::summarise(flux_co2_nmol_g_s = mean(flux_co2_nmol_g_s),
                     flux_co2_nmol_gC_s = mean(flux_co2_nmol_gC_s),
                     flux_ch4_nmol_g_s = mean(flux_ch4_nmol_g_s)) %>% 
    left_join(corekey_subset, by = "Core") %>% 
    dplyr::select(Core, Core_assignment, texture, sat_level, treatment, 
                  flux_co2_nmol_g_s, flux_co2_nmol_gC_s, flux_ch4_nmol_g_s),
  
  
  mean_flux = 
    gf_core %>% 
    group_by(Core_assignment, texture, treatment, sat_level) %>% 
    dplyr::summarise(se = sd(flux_co2_nmol_g_s)/sqrt(n()),
                     se_C = sd(flux_co2_nmol_gC_s)/sqrt(n()),
                     flux_co2_nmol_g_s = mean(flux_co2_nmol_g_s),
                     flux_co2_nmol_gC_s = mean(flux_co2_nmol_gC_s)
    )
)

## OUTPUT ----
make(plan)
fluxes = readd(gf_core) %>% write.csv("data/processed/picarro_fluxes.csv", row.names = FALSE)
mean_flux = readd(mean_flux) %>% write.csv("data/processed/picarro_meanfluxes.csv", row.names = FALSE)