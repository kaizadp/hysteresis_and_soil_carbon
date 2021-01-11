# HYSTERESIS AND SOIL C
# Kaizad F. Patel 
# WATER RETENTION CURVES
# Oct. 25, 2019

## this script processes fitted HYPROP + WP4C data
## and calculates water release by pore size

source("code/0-hysteresis_packages.R")

# -------------------------------------------------------------------------


# hyprop with wp4c -- july 30 -- vg ----------------------------------------------

# Step 1. load files ----
filePaths <- list.files(path = "data/wrc/vg_wp4c-07-30",pattern = "*.xlsx", full.names = TRUE)

wrc <- do.call(rbind, lapply(filePaths, function(path) {
  df <- read_excel(path, sheet="Fitting-Retention Θ(pF)")
  df[["source"]] <- rep(path, nrow(df))
  df}))

#
# Step 2. process file ----
wrc_processed = 
  wrc %>% 
  dplyr::rename(pF = `pF [-]`,
                vol_water_perc = `Water Content [Vol%]`) %>% 
  #filter(pF>=0) %>% 
  dplyr::mutate(treatment = case_when(grepl("drying",source)~"drying",
                                      grepl("wetting",source)~"wetting"),
                texture = case_when(grepl("scl",source)~"SCL",
                                    grepl("sl",source)~"SL"),
                grav_water_perc = case_when(texture=="SCL" ~ vol_water_perc/0.4,
                                            texture=="SL" ~ vol_water_perc/0.5)) %>% 
  group_by(texture, treatment) %>% 
  dplyr::mutate(kPa = round((10^pF)/10,2),
                perc_sat = round((vol_water_perc/max(vol_water_perc))*100,2)) %>% 
  dplyr::filter(#kPa < 200,
    pF>=0)

#
# Step 3. water release -----------------------------------------------------------

## determine the volume of water released with successive increase in suction
## drying curves only

release_drying = 
  wrc_processed %>% 
  select(vol_water_perc, treatment, texture, kPa) %>% 
  # keep only the SCL drying data
  filter(treatment %in% "drying") %>% 
  # calculate wet pore size using the Kelvin equation
  mutate(pore_um = round(300/kPa,2)) %>% 
  # for repeating kPa/pore, calculate mean of water content
  group_by(pore_um, texture, treatment) %>% 
  dplyr::summarise(vol_water_perc = round(mean(vol_water_perc),2)) %>% 
  ungroup() %>% 
  # then create bins in increments of 10 (0-3000, 300 breakpoints)
  mutate(x_bins = cut(pore_um, breaks = 300)) %>% 
  # split the bins into start and stop columns
  separate(x_bins, c("start", "stop"), sep = ",") %>% 
  mutate(stop = str_replace(stop, "]",""),
         stop = as.numeric(stop),
         start = stri_replace_all_fixed(start, "(",""),
         #         start = str_replace(start, "-",""),
         start = as.numeric(start)) %>%
  group_by(texture) %>% 
  arrange(desc(pore_um)) %>% 
  ungroup()

release_drying_diff = 
  release_drying %>% 
  group_by(texture) %>% 
  # calculate sequential loss of water (lag)
  mutate(Diff = (vol_water_perc - lag(vol_water_perc))*-1) %>% 
  na.omit() 

# ^^  this leaves the lowest value as the residual water (0um pore), not included in the diff
#     so create a new file with just the residual moisture, and then join it with the diff file

release_drying_residual = 
  release_drying_diff %>% 
  group_by(texture) %>% 
  filter(vol_water_perc==min(vol_water_perc)) %>% 
  ungroup() %>% 
  mutate(Diff = vol_water_perc)

# now merge
release_drying_diff2 = 
  release_drying_diff %>% 
  rbind(release_drying_residual) %>% 
  group_by(texture) %>% 
  mutate(Diff_perc = round((Diff/max(vol_water_perc))*100,2))


# Step 4. outputs -----------------------------------------------------------------

write.csv(wrc_processed, "data/processed/wrc.csv", row.names = F)
write.csv(release_drying_diff2, "data/processed/wrc_drying_release.csv", row.names = F)
