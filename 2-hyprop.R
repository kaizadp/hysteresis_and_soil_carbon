# HYSTERESIS AND SOIL C
# Kaizad F. Patel 
# Oct. 25, 2019

source("0-hysteresis_packages.R")

# input file

hyprop = 
  read_csv("data/hyprop_fitting_vg.csv") %>% 
  rename(tension_pF = `pF [-]`,
         moisture_vol = `Water Content [Vol%]`) %>% 
group_by(soiltype) %>% 
  dplyr::mutate(kPa = round((10^tension_pF)/10,2),
                perc_sat = (moisture_vol/max(moisture_vol))*100) %>% 
  dplyr::filter(kPa < 200,
                tension_pF>=0)
names(hyprop)

ggplot(hyprop, aes(y = tension_pF, x = moisture_vol, color = treatment))+
  geom_path()+
  facet_wrap(~soiltype)

ggplot(hyprop, aes(y = kPa, x = perc_sat, color = treatment, linetype=treatment))+
  geom_path(size=1)+
  facet_wrap(.~soiltype)+
  theme_kp()
