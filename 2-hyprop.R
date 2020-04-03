# HYSTERESIS AND SOIL C
# Kaizad F. Patel 
# Oct. 25, 2019

source("0-hysteresis_packages.R")

# input file

hyprop = 
  read_csv("data/hyprop_fitting_vg.csv") %>% 
  rename(tension_pF = `pF [-]`,
         moisture_vol = `Water Content [Vol%]`) %>% 
  dplyr::mutate(soiltype = recode(soiltype,
                                   `soil` = "Soil (sandy clay loam)",
                                   `soil_sand` = "Soil + Sand")) %>% 
  group_by(soiltype) %>% 
  dplyr::mutate(kPa = round((10^tension_pF)/10,2),
                perc_sat = (moisture_vol/max(moisture_vol))*100) %>% 
  dplyr::filter(kPa < 200,
                tension_pF>=0)
## names(hyprop)
## 
## ggplot(hyprop, aes(y = tension_pF, x = moisture_vol, color = treatment))+
##   geom_path()+
##   facet_wrap(~soiltype)
## 
 ggplot(hyprop, aes(x = kPa, y = perc_sat, color = treatment, linetype=treatment))+
   geom_path(size=1)+
   facet_wrap(.~soiltype)+
   theme_kp()

 
 
 
library(soiltexture) 
 
 
TT.plot(class.sys = "USDA.TT")


hysteresis_texture = data.frame(
  "SAND" = c(46.08,64.05),
  "SILT" = c(25.37,16.91),
  "CLAY"= c(28.56,19.04)
)

TT.plot(
  class.sys= "USDA.TT",
  tri.data= hysteresis_texture,
  main= "Soil texture data"
  )


soil.texture(soiltexture=hysteresis_texture, main="", at=seq(0.1, 0.9, by=0.1),
             axis.labels=c("percent sand", "percent silt",
                           "percent clay"),
             tick.labels=list(l=seq(10, 90, by=10), r=seq(10, 90, by=10),
                              b=seq(10, 90, by=10)),
             show.names=FALSE, show.lines=TRUE, col.names="gray",
             bg.names=par("bg"), show.grid=FALSE, col.axis="black",
             col.lines="gray", col.grid="gray", lty.grid=3,
             show.legend=FALSE, label.points=FALSE, point.labels=NULL,
             col.symbols="black", pch=par("pch"))
		
		
library(plotrix)







  
  
  