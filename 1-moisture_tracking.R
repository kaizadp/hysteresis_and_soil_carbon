# HYSTERESIS AND SOIL C
# Kaizad F. Patel 
# Oct. 25, 2019

# tracking moisture content in soil cores
### taken from BBL's script TESDrydown/drake_plan.R
# hit run/knit on the RMarkdown file, no need to run this script separately. 


# drake plan

library(drake)
pkgconfig::set_config("drake::strings_in_dots" = "literals")
library(ggplot2)
theme_set(theme_bw())
library(googlesheets)
library(readxl)
library(tidyr)
library(dplyr)
library(lubridate)
library(drake)

# create a function that combines all the data needed for the weight/moisture calculation
# 1. core key
# 2. initial core weights, including dry weight 
# 3. mass tracking file
#  read_massdata <- function(fqfn) {
#    ca <- readxl::read_excel("data/Core_key.xlsx") %>% 
#      dplyr::select(1:7)
#    
#    dry <- read_excel("data/Core_weights.xlsx", sheet = "initial") %>% 
#      dplyr::select(Core, EmptyWt_g, DryWt_g)
#    
#   readxl::read_excel("data/Core_weights.xlsx", sheet = "Mass_tracking") %>% 
#      filter(!is.na(Site), Site != "AMB", Core != "0") %>% # remove unnecessary crap
#      left_join(ca, by = "Core") %>% 
#      left_join(dry, by = "Core") %>% 
#      filter(is.na(skip)) %>% # exclude the rows as needed
#     # dplyr::select(Core, Stop_datetime, Seq.Program, Core_assignment, EmptyWt_g, DryWt_g, Mass_g, Moisture) %>% 
#      dplyr::mutate(Stop_datetime = as.POSIXct(strptime(Stop_datetime,format = "%m/%d/%Y %H:%M")), #f-ing datetime
#  # calculate moisture content for each core
#             DryWt_g = round(DryWt_g,2),
#             MoistWt_g = Mass_g - EmptyWt_g,
#             Water_g = MoistWt_g - DryWt_g,
#             Moisture_perc = round(((Water_g/DryWt_g)*100),2))
#  }


### DOING THIS WITHOUT F-ING DRAKE

read_core_key <- function(filename) {
  readxl::read_excel("data/Core_key.xlsx") %>%
    dplyr::select(Core, soil_type, treatment, trt, Core_assignment, Moisture, skip)
}
ca <- read_core_key("data/Core_key.xlsx")

read_core_dryweights <- function(filename, sheet) {
  read_excel(filename, sheet = sheet) %>% 
    dplyr::select(Core, EmptyWt_g, DryWt_g)
}
dry <- read_core_dryweights("data/Core_weights.xlsx", sheet = "initial")

read_core_masses <- function(filename, sheet, core_key, core_dry_weights) {
  readxl::read_excel(filename, sheet = sheet) %>% 
    filter(!is.na(Site), Site != "AMB", Core != "0") %>% # remove unnecessary crap
    left_join(core_key, by = "Core") %>% 
    left_join(core_dry_weights, by = "Core") %>% 
    filter(is.na(skip)) %>% # exclude the rows as needed
    dplyr::select(Core, Start_datetime, Stop_datetime, Seq.Program, Valve,
                  Core_assignment, EmptyWt_g, DryWt_g, Mass_g, Moisture) %>% 
    dplyr::mutate(Start_datetime = mdy_hm(Start_datetime, tz = "America/Los_Angeles"),
                  Stop_datetime = mdy_hm(Stop_datetime, tz = "America/Los_Angeles"),
                  # calculate moisture content for each core
                  DryWt_g = round(DryWt_g,2),
                  MoistWt_g = Mass_g - EmptyWt_g,
                  Water_g = MoistWt_g - DryWt_g,
                  Moisture_perc = round(((Water_g / DryWt_g) * 100), 2))
}
mass <- read_core_masses("data/Core_weights.xlsx", sheet = "Mass_tracking", ca, dry)
