# R script for Kenton Rod's DOC experiment
# Kaizad F. Patel
# September 2019
# ----------------------------------------------------------------------------------- -
# ----------------------------------------------------------------------------------- -


### save all raw data files as .csv files in the directory "data/wsoc_data"
### make sure all the .csv files have the same column names

# install packages defined in the linked script
source("0-hysteresis_packages.R")
library(purrr)


wsoc_plan = drake_plan(
  
# step 1. import all files ---------------------------- ####

# import and merge all data files in the folder
wsoc_raw = sapply(list.files(path = "data/wsoc_data/",pattern = "*.csv", full.names = TRUE),
                  read_csv, simplify = FALSE) %>% bind_rows(),
wsoc_key = read_csv("data/WSOC_SAMPLE_KEY.csv"), # wsoc key
core_key = read.csv(COREKEY) %>% mutate(Core = as.character(Core)), # core key

# process
wsoc_processed = 
  wsoc_raw %>% 
# remove the appropriate rows
# in this case, we want Remove==NA and Excluded==1
  filter(is.na(Remove)) %>% 
# subset only the relevant columns, Sample Name and Area
  dplyr::select(`Sample Name`, Area) %>% 
  group_by(`Sample Name`) %>% 
  dplyr::summarise(Area = mean(Area)) %>% 
# the `Sample Name`` column is actually vial numbers, recorded as "Vial 1", "Vial 2", etc. Create a new column Vial_no by removing the "Vial " string at the start of the name.
  mutate(Vial_no = str_remove(`Sample Name`, "Vial ")) %>%
# now combine with the wsoc_key
  left_join(select(wsoc_key, -(DD:YYYY)), by = "Vial_no", all.x=T),
  
# create a new file for just the calibration standards
wsoc_calib = 
  wsoc_processed %>% 
  filter(Type=="calibration")->  wsoc_calib,


#
# step 2.  calibration curves ---------------------------- ####
# plot calibration curve for each run 
gg_calib = 
  ggplot(wsoc_calib, aes(x = Area, y = Calib_ppm))+
  geom_smooth(method = "lm", color = "gray", alpha = 0.5, se = F)+
  geom_point()+
#  facet_wrap(~Run)+
  ggtitle("Calibration curves")+
  ylab("NPOC, mg/L")+
  theme_bw(),

save_plot("data/processed/wsoc_calibration_curves.tiff", gg_calib, base_height = 7, base_width = 7),

# create new columns with the slope and intercept for each calibration curve
wsoc_calib_slope = 
  wsoc_calib %>% 
 # dplyr::group_by(Run) %>% 
  dplyr::summarize(slope = lm(Calib_ppm~Area)$coefficients["Area"], 
                   intercept = lm(Calib_ppm~Area)$coefficients["(Intercept)"]),

### if we are using a single calibration curve across all samples, then do this 
SLOPE = mean(wsoc_calib_slope$slope),
INTERCEPT = mean(wsoc_calib_slope$intercept),

#


# step 3. calculate DOC concentrations ---------------------------- ####
# first, create a file of only the sample data. no calibration or qaqc data
wsoc_samples = 
  wsoc_processed %>% 
  filter(Type=="sample") %>% 
# next calculate DOC as y = mx + c
  mutate(npoc = Area*SLOPE + INTERCEPT) %>% 
# dilution conversions
  mutate(npoc_mg_l = round(npoc*Dilution,2)) %>% 
# subset only the relevant columns now
  dplyr::select(`Sample name`,npoc_mg_l) %>% 
# rename so that we can merge easily later
  rename(Core=`Sample name`) %>% 
  left_join(core_key, by="Core"),

#


# step 4. calculate as mg/g ---------------------------- ####

# first, we need to retrieve weights of soil used for the extraction
wsoc_weights = 
  read_excel("data/Subsampling_weights.xlsx", sheet = "subsampling") %>% 
  dplyr::select(Core_No, Moisture_perc, WSOC_weighed_g) %>% 
  dplyr::rename(gmoist = Moisture_perc,
                Core=Core_No) %>% 
  dplyr::mutate(WSOC_drywt_g  = round(WSOC_weighed_g/((gmoist/100)+1),2),
                WSOC_water_g = WSOC_weighed_g - WSOC_drywt_g),

wsoc_results = wsoc_samples %>% 
  left_join(wsoc_weights, by = "Core") %>% 
  dplyr::mutate(wsoc_mg_g = round(npoc_mg_l * (40+WSOC_water_g)/(WSOC_drywt_g*1000),3),
                wsoc_mg_gC = round(npoc_mg_l * (40+WSOC_water_g)/(Carbon_g*1000),3),
                perc_sat_actual = case_when(soil_type=="Soil" ~ (gmoist/140)*100,
                                            soil_type=="Soil_sand" ~ (gmoist/100)*100)) %>% 
  dplyr::select(Core,soil_type, texture, treatment, moisture_lvl, perc_sat, gmoist,npoc_mg_l, wsoc_mg_g,wsoc_mg_gC,perc_sat_actual),

write.csv(wsoc_results, WSOC, row.names = F, na=""))

message("Now type: clean(garbage_collection = T)
and then: make(wsoc_plan)
GRRR drake")



### post-drake processing
wsoc_processed = readd(wsoc_processed)
wsoc_raw = readd(wsoc_raw)
wsoc_processed = readd(wsoc_processed)


wsoc_results = readd(wsoc_results)

ggplot(wsoc_results, aes(x = perc_sat, y = wsoc_mg_g, color = treatment))+
  geom_point()+
  facet_grid(soil_type~.)+
  labs(caption="normalized to soil weight (g)")+
  scale_x_reverse(name = "percent saturation")+
  theme_kp()
  
ggplot(wsoc_results, aes(x = perc_sat, y = wsoc_mg_gC, color = treatment))+
  geom_point()+
  facet_grid(soil_type~.)+
  labs(caption="normalized to Carbon (g)")+
  scale_x_reverse(name = "percent saturation")+
  theme_kp()

ggplot(wsoc_results[!wsoc_results$treatment=="FM",], aes(x = gmoist, y = wsoc_mg_g, color = treatment))+
  geom_point()+
  geom_smooth(data = wsoc_results[!wsoc_results$moisture_lvl==5&!wsoc_results$treatment=="FM",],aes(x = gmoist, y = wsoc_mg_g, color = treatment))+
  scale_x_reverse(name = "gmoist")+
  theme_kp()

ggplot(wsoc_results[!wsoc_results$treatment=="FM",], aes(x = perc_sat_actual, y = wsoc_mg_g, color = treatment))+
  geom_point()+
  geom_smooth(data = wsoc_results[!wsoc_results$moisture_lvl==5&!wsoc_results$treatment=="FM",],aes(x = perc_sat_actual, y = wsoc_mg_g, color = treatment))+
  facet_grid(soil_type~.)+
  scale_x_reverse(name = "percent saturation")+
  theme_kp()
