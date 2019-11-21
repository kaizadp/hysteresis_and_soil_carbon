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

# step 1. import all files ---------------------------- ####

# import and merge all data files in the folder
wsoc_raw = sapply(list.files(path = "data/wsoc_data/",pattern = "*.csv", full.names = TRUE) ,
                  read_csv, simplify = FALSE) %>% bind_rows()

# wsoc key
wsoc_key = read_csv("data/WSOC_SAMPLE_KEY.csv")

# core key
core_key = read_csv("data/Core_key.csv")
core_key = read_excel("data/Core_key.xlsx")


# get the names of the columns
names(wsoc_raw)

wsoc_raw %>% 
# remove the appropriate rows
# in this case, we want Remove==NA and Excluded==1
  filter(is.na(Remove),
         Excluded=="1") %>% 
# subset only the relevant columns, Sample Name and Area
  dplyr::select(`Sample Name`, Area) %>% 
# the `Sample Name`` column is actually vial numbers, recorded as "Vial 1", "Vial 2", etc. Create a new column Vial_no by removing the "Vial " string at the start of the name.
  mutate(Vial_no = str_remove(`Sample Name`, "Vial ")) %>%
# now combine with the wsoc_key
  left_join(select(wsoc_key, -(DD:YYYY)), by = "Vial_no", all.x=T) -> wsoc_processed 
  

# create a new file for just the calibration standards
wsoc_calib = 
  wsoc_processed %>% 
  filter(Type=="calibration")->  wsoc_calib


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
  theme_bw()

save_plot("data/processed/wsoc_calibration_curves.tiff", gg_calib, base_height = 7, base_width = 7)

# create new columns with the slope and intercept for each calibration curve
wsoc_calib %>% 
 # dplyr::group_by(Run) %>% 
  dplyr::summarize(slope = lm(Calib_ppm~Area)$coefficients["Area"], 
                   intercept = lm(Calib_ppm~Area)$coefficients["(Intercept)"])->
  wsoc_calib_slope

### if we are using a single calibration curve across all samples, then do this 
SLOPE = mean(wsoc_calib_slope$slope)
INTERCEPT = mean(wsoc_calib_slope$intercept)

#


# step 3. calculate DOC concentrations ---------------------------- ####
# first, create a file of only the sample data. no calibration or qaqc data
wsoc_processed %>% 
  filter(Type=="sample") %>% 
# next calculate DOC as y = mx + c
  mutate(npoc = Area*SLOPE + INTERCEPT) %>% 
# dilution conversions
  mutate(npoc_mg_l = round(npoc*Dilution,2)) %>% 
# subset only the relevant columns now
  dplyr::select(`Sample name`,npoc_mg_l) %>% 
# rename so that we can merge easily later
  rename(Core=`Sample name`)->
  wsoc_samples



write_csv(DOC_data_processed6_batch, path = "2_processeddata/doc_concentrations_batch.csv", na="")
write_csv(DOC_data_processed6_column, path = "2_processeddata/doc_concentrations_column.csv", na="")



