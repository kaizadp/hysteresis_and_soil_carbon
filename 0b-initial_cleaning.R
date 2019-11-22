
source("0-hysteresis_packages.R")

### CONSTANT VALUES USED IN CALCULATIONS
TC = 8.34 #carbon percentage
GMOISTURE = 0.7123 # 71.23% w/w gravimetric moisture
GMOISTURE_SAND = round(GMOISTURE*20/30,4)
###

# process and clean the core_weights file
core_weights = 
  read_excel("data/Core_weights.xlsx", sheet = "initial") %>% 
  dplyr::select(Core, EmptyWt_g, Total_g,Soil_g, Sand_g) %>% 
  dplyr::mutate(DryWt_g = round((Soil_g/(GMOISTURE+1))+Sand_g,2),
                Carbon_g = round((Soil_g/(GMOISTURE+1))*(TC/100),2))

# process and clean the core_key file
core_key = 
  read_excel("data/Core_key.xlsx") %>% 
  select(Core, soil_type, treatment, trt, Core_assignment, Moisture, skip) %>% 

# create new columns for various factors
  
  dplyr::mutate(texture = case_when(soil_type=="Soil"~"SCL",
                                    soil_type=="Soil_sand"~"SL"),
                Moisture2 = if_else(soil_type=="Soil"&Moisture=="fm",GMOISTURE*100,
                                   if_else(soil_type=="Soil_sand"&Moisture=="fm",GMOISTURE_SAND*100,as.numeric(Moisture))),
                
                
                Status = case_when(grepl("_D$", Core_assignment) ~ "Dry",
                                   grepl("_W$", Core_assignment) ~ "Wet",
                                   grepl("_fm$", Core_assignment) ~ "FM"),
                
                
                moisture_lvl = if_else(soil_type=="Soil"&Moisture=="sat","140",
                                       if_else(soil_type=="Soil_sand"&Moisture=="sat","100",
                                               if_else(Moisture=="dry","5",
                                                       if_else(soil_type=="Soil_sand"&Moisture=="100","40",as.character((Moisture)))))),
                
                
                perc_sat = case_when(soil_type=="Soil"~(as.integer(as.integer(as.character(moisture_lvl))/140*100)),
                                             soil_type=="Soil_sand"~(as.integer(as.integer(as.character(moisture_lvl))/100*100)))) %>% 
  
  
  dplyr::mutate(moisture_lvl = factor(moisture_lvl, levels = c("140","100","75","50","40","5","fm"))) %>% 
  left_join(core_weights, by = "Core") %>% 
  filter(is.na(skip)) %>% # exclude the rows as needed
  dplyr::mutate(MoistWt_g = Total_g - EmptyWt_g,
                Water_g = MoistWt_g - DryWt_g,
                Moisture_perc = round(((Water_g / DryWt_g) * 100), 2)) %>% 
  dplyr::select(-(EmptyWt_g:Sand_g), -(MoistWt_g:Water_g))

### OUTPUT
write.csv(core_key,COREKEY, row.names = F,na = "")
