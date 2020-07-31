# HYSTERESIS AND SOIL C
# Kaizad F. Patel 
# Oct. 25, 2019

source("code/0-hysteresis_packages.R")

#
          ###  load files ----
filePaths <- list.files(path = "data/wrc/vg_pdi",pattern = "*.xlsx", full.names = TRUE)


          ###  fitted data -------------------------------------------------------------
wrc <- do.call(rbind, lapply(filePaths, function(path) {
  df <- read_excel(path, sheet="Fitting-Retention Θ(pF)")
  df[["source"]] <- rep(path, nrow(df))
  df}))

wrc_processed = 
  wrc %>% 
  dplyr::rename(pF = `pF [-]`,
                vol_water_perc = `Water Content [Vol%]`) %>% 
  #filter(pF>=0) %>% 
  dplyr::mutate(treatment = case_when(grepl("drying",source)~"drying",
                                      grepl("wetting",source)~"wetting"),
                texture = case_when(grepl("scl",source)~"SCL",
                                      grepl("sl",source)~"SL")) %>% 
  group_by(texture) %>% 
  dplyr::mutate(kPa = round((10^pF)/10,2),
                perc_sat = (vol_water_perc/max(vol_water_perc))*100) %>% 
  dplyr::filter(#kPa < 200,
                pF>=0)

                
                
wrc_processed %>% 
  ggplot(aes(x = pF, y = vol_water_perc, color = treatment))+
  geom_path()+
  facet_wrap(~texture)

wrc_processed %>% 
  ggplot(aes(y = kPa, x = vol_water_perc, color = treatment))+
  geom_path()+
  scale_y_log10(labels = scales::comma)+
  facet_wrap(~texture)

wrc_processed %>% 
  ggplot(aes(x = kPa, y = vol_water_perc, color = treatment))+
  geom_path(size=1)+
  scale_x_log10(labels = scales::comma,
                limits = c(0.1,1000000)
                )+
  labs(title = "fitted",
       y = "moisture (% v/v)")+
  

  annotate("text", label = "300 um \npore", x = 1, y = 0.5)+
#  annotate("text", label = "30 um", x = 10, y = 0)+
  annotate("text", label = "3 um", x = 100, y = 0)+
#  annotate("text", label = "0.3 um", x = 1000, y = 0)+
  annotate("text", label = "0.03 um", x = 10000, y = 0)+
#  annotate("text", label = "0.003 um", x = 100000, y = 0)+
  
  
  facet_wrap(~texture)+
  theme_kp()

#

          ###  unfitted data -----------------------------------------------------------

wrc_unfit <- do.call(rbind, lapply(filePaths, function(path) {
  df <- read_excel(path, sheet="Evaluation-Retention Θ(pF)")
  df[["source"]] <- rep(path, nrow(df))
  df}))

wrc_processed_unfit = 
  wrc_unfit %>% 
  dplyr::rename(pF = `pF [-]`,
                vol_water_perc = `Water Content [Vol%]`) %>% 
  #filter(pF>=0) %>% 
  dplyr::mutate(treatment = case_when(grepl("drying",source)~"drying",
                                      grepl("wetting",source)~"wetting"),
                texture = case_when(grepl("scl",source)~"SCL",
                                    grepl("sl",source)~"SL")) %>% 
  group_by(texture) %>% 
  dplyr::mutate(kPa = round((10^pF)/10,2),
                perc_sat = (vol_water_perc/max(vol_water_perc))*100) %>% 
  dplyr::filter(#kPa < 200,
    pF>=0)

## with wp4c data -- 1

x = tribble(
  ~pF, ~vol,
  3.17, 76.58,
  3.18, 46.47,
  3.19, 56.62,
  3.21, 33.05,
  3.61, 26.51,
  4.16, 14.07,
  5.06, 4.58
) %>% 
  dplyr::mutate(treatment="wetting")


wrc_processed_unfit %>% 
  arrange(kPa) %>% 
  ggplot(aes(x = kPa, y = vol_water_perc, color = treatment, shape = treatment))+
  geom_point(size=1.5)+
  geom_path()+
  geom_point(data = x, aes(x = pF, y = vol))+
  scale_shape_manual(values = c(1,16))+
#  scale_x_log10(labels = scales::comma, limits = c(0.1,10000))+
  scale_x_continuous(trans = log10_trans(),
                     labels = scales::comma,
                     #sec.axis = sec_axis(~ .^-1 * 300*1000, name = "pore size (nm)", labels = scales::comma)
                     )+
  geom_vline(xintercept = 100)+
  facet_wrap(~texture)+
  labs(title = "unfitted",
       y = "moisture (% v/v)")+
  annotate("text", label = "WP4C", x = 500, y = 10)+
  annotate("text", label = "HYPROP", x = 10, y = 10)+

  annotate("text", label = "300 um", x = 1, y = 2)+
#  annotate("text", label = "30 um", x = 10, y = 2)+
  annotate("text", label = "3 um", x = 100, y = 2)+
#  annotate("text", label = "0.3 um", x = 1000, y = 2)+
  annotate("text", label = "0.03 um", x = 10000, y = 2)+
#  annotate("text", label = "0.003 um", x = 100000, y = 2)+
  
  theme_kp()
#  theme(strip.text = element_text(position = "bottom"))

## with wp4c data -- 1

density = 0.54 # g/cm3

wp4c = read.csv("data/wrc/scl_wp4c.csv") %>% 
  select(tray_wt_g, drysoil_g, wp4c_weight_g, MPa, pF, mode) %>% 
  mutate(kPa = round((10^pF)/10,2),
                water_g = wp4c_weight_g - (tray_wt_g + drysoil_g),
         grav_perc = (water_g/drysoil_g)*100,
         vol = grav_perc*density,
         perc_sat = (vol/max(vol))*100,
         treatment="Wetting",
         soiltype="Soil (sandy clay loam)")


wrc_processed_unfit %>% 
  arrange(kPa) %>% 
  ggplot(aes(x = kPa, y = vol_water_perc, color = treatment, shape = treatment))+
  geom_point(size=1.5)+
  geom_path()+
  geom_point(data = wp4c, aes(x = pF, y = vol), color = "black")+
  scale_shape_manual(values = c(1,16))+
  #  scale_x_log10(labels = scales::comma, limits = c(0.1,10000))+
  scale_x_continuous(trans = log10_trans(),
                     labels = scales::comma,
                     #sec.axis = sec_axis(~ .^-1 * 300*1000, name = "pore size (nm)", labels = scales::comma)
  )+
  geom_vline(xintercept = 100)+
  facet_wrap(~texture)+
  labs(title = "unfitted",
       y = "moisture (% v/v)")+
  annotate("text", label = "WP4C", x = 500, y = 10)+
  annotate("text", label = "HYPROP", x = 10, y = 10)+
  
  annotate("text", label = "300 um", x = 1, y = 2)+
  #  annotate("text", label = "30 um", x = 10, y = 2)+
  annotate("text", label = "3 um", x = 100, y = 2)+
  #  annotate("text", label = "0.3 um", x = 1000, y = 2)+
  annotate("text", label = "0.03 um", x = 10000, y = 2)+
  #  annotate("text", label = "0.003 um", x = 100000, y = 2)+
  
  theme_kp()






#
          ###  old ---------------------------------------------------------------------


          ###  input file

          ###  prop = 
          ###  read_csv("data/hyprop_fitting_vg.csv") %>% 
          ###  rename(tension_pF = `pF [-]`,
          ###         moisture_vol = `Water Content [Vol%]`) %>% 
          ###  dplyr::mutate(soiltype = recode(soiltype,
          ###                                   `soil` = "Soil (sandy clay loam)",
          ###                                   `soil_sand` = "Soil + Sand")) %>% 
          ###  group_by(soiltype) %>% 
          ###  dplyr::mutate(kPa = round((10^tension_pF)/10,2),
          ###                perc_sat = (moisture_vol/max(moisture_vol))*100) %>% 
          ###  dplyr::filter(kPa < 200,
          ###                tension_pF>=0)

          ###  prop_subset = 
          ###  hyprop %>% 
          ###  dplyr::mutate(pores_um = round(300/kPa,2),
          ###                perc_sat = round(perc_sat,1)) 
          ###   filter(perc_sat %in% c(5,35,50,75,100))


          ###  
          ###  
          ###   ggplot trial with wp4c


          ###  plot(hyprop, aes(x = kPa, y = perc_sat, color = treatment, linetype=treatment))+
          ###  geom_path(size=1.5)+
          ###  scale_color_manual(labels = c("drying","rewetting"), values = c("darkorange2","gray40"), na.translate=F)+
          ###  scale_linetype_manual(labels = c("drying","rewetting"), values = c("solid","twodash"), na.translate=F)+
          ###  geom_point(data = wp4c, aes(x = kPa, y = perc_sat), color = "black")+
          ###  
          ###  facet_wrap(.~soiltype)+
          ###  xlab ("tension, kPa (log scale)")+
          ###  ylab ("percent saturation")+
          ###  #ylim(0,100)+
          ###  #  scale_x_reverse(name = "percent saturation")+
          ###  scale_x_log10()+
          ###  # xlim(0,100)+
          ###  theme_kp()



          ###    
          ###  
          ###  
# library(soiltexture) 
#  
#  
# TT.plot(class.sys = "USDA.TT")
# 
# 
# hysteresis_texture = data.frame(
#   "SAND" = c(46.08,64.05),
#   "SILT" = c(25.37,16.91),
#   "CLAY"= c(28.56,19.04)
# )
# 
# TT.plot(
#   class.sys= "USDA.TT",
#   tri.data= hysteresis_texture,
#   main= "Soil texture data"
#   )
# 
# 
# soil.texture(soiltexture=hysteresis_texture, main="", at=seq(0.1, 0.9, by=0.1),
#              axis.labels=c("percent sand", "percent silt",
#                            "percent clay"),
#              tick.labels=list(l=seq(10, 90, by=10), r=seq(10, 90, by=10),
#                               b=seq(10, 90, by=10)),
#              show.names=FALSE, show.lines=TRUE, col.names="gray",
#              bg.names=par("bg"), show.grid=FALSE, col.axis="black",
#              col.lines="gray", col.grid="gray", lty.grid=3,
#              show.legend=FALSE, label.points=FALSE, point.labels=NULL,
#              col.symbols="black", pch=par("pch"))
# 		
# 		
# library(plotrix)
# 






  
  
  

# hyprop with wp4c -- july 9/29 -- vg ----------------------------------------------

filePaths <- list.files(path = "data/wrc/vg_wp4c-07-30",pattern = "*.xlsx", full.names = TRUE)

wrc <- do.call(rbind, lapply(filePaths, function(path) {
  df <- read_excel(path, sheet="Fitting-Retention Θ(pF)")
  df[["source"]] <- rep(path, nrow(df))
  df}))

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

##
wrc_processed %>% 
  #dplyr::mutate(skip = case_when(grepl("sl_drying",source)~"skip",
  #                             grepl("scl_drying",source)~"skip")) %>% 
  #filter(is.na(skip)) %>% 
  ggplot(aes(x = kPa, y = grav_water_perc, color = treatment, linetype=treatment, group = source))+
  geom_path(size=1.5)+
  scale_color_manual(labels = c("drying","rewetting"), values = c("darkorange2","gray40"), na.translate=F)+
  scale_linetype_manual(labels = c("drying","rewetting"), values = c("solid","twodash"), na.translate=F)+
  
  facet_wrap(.~texture)+
  xlab ("tension, kPa (log scale)")+
  ylab ("gravimetric moisture (%)")+
  scale_x_continuous(trans = scales::log10_trans(), labels = scales::comma, 
                     sec.axis = sec_axis(~ .^-1 * 300, name = "pore size (um)", labels = scales::comma))+
  geom_hline(yintercept = 5, size=0.5, color = "grey80")+
  geom_hline(yintercept = 35, size=0.5, color = "grey80")+
  geom_hline(yintercept = 50, size=0.5, color = "grey80")+
  geom_hline(yintercept = 75, size=0.5, color = "grey80")+
  #coord_flip()+
  theme_kp()+
  theme(panel.grid = element_blank())


##

wrc_processed %>% 
  dplyr::mutate(skip = case_when(grepl("sl_drying",source)~"skip",
                                 grepl("scl_drying",source)~"skip")) %>% 
  filter(is.na(skip)) %>% 
  filter(treatment=="drying") %>% 
  ggplot(aes(x = kPa, y = grav_water_perc, color = texture, group = source))+
  geom_path(size=1.5)+
  scale_color_manual(#labels = c("drying","rewetting"), 
                     values = c("darkorange2","gray40"), na.translate=F)+
  scale_linetype_manual(labels = c("drying","rewetting"), values = c("solid","twodash"), na.translate=F)+
  
  #facet_wrap(.~texture)+
  labs (x = "tension, kPa (log scale)",
        y = "gravimetric moisture (%)",
        title = "drying curves only")+
  scale_x_continuous(trans = scales::log10_trans(), labels = scales::comma, 
                     sec.axis = sec_axis(~ .^-1 * 300, name = "pore size (um)", labels = scales::comma))+
  geom_hline(yintercept = 5, size=0.5, color = "grey80")+
  geom_hline(yintercept = 35, size=0.5, color = "grey80")+
  geom_hline(yintercept = 50, size=0.5, color = "grey80")+
  geom_hline(yintercept = 75, size=0.5, color = "grey80")+
  theme_kp()+
  theme(panel.grid = element_blank())







#
# hyprop only -- july 29 -- vg ----------------------------------------------

filePaths <- list.files(path = "data/wrc/vg_hyproponly_07-29",pattern = "*.xlsx", full.names = TRUE)

wrc <- do.call(rbind, lapply(filePaths, function(path) {
  df <- read_excel(path, sheet="Fitting-Retention Θ(pF)")
  df[["source"]] <- rep(path, nrow(df))
  df}))

wrc_processed = 
  wrc %>% 
  dplyr::rename(pF = `pF [-]`,
                vol_water_perc = `Water Content [Vol%]`) %>% 
  #filter(pF>=0) %>% 
  dplyr::mutate(treatment = case_when(grepl("drying",source)~"drying",
                                      grepl("wetting",source)~"wetting"),
                texture = case_when(grepl("scl",source)~"SCL",
                                    grepl("sl",source)~"SL")) %>% 
  group_by(texture) %>% 
  dplyr::mutate(kPa = round((10^pF)/10,2),
                perc_sat = round((vol_water_perc/max(vol_water_perc))*100,2)) %>% 
  dplyr::filter(#kPa < 200,
    pF>=0)

##

wrc_processed %>% 
  dplyr::mutate(skip = case_when(grepl("sl_drying",source)~"skip",
                                 grepl("scl_drying",source)~"skip")) %>% 
  filter(is.na(skip)) %>% 
  filter(treatment=="drying") %>% 
  ggplot(aes(x = kPa, y = perc_sat, color = texture, group = source))+
  geom_path(size=1.5)+
  scale_color_manual(#labels = c("drying","rewetting"), 
    values = c("darkorange2","gray40"), na.translate=F)+
  scale_linetype_manual(labels = c("drying","rewetting"), values = c("solid","twodash"), na.translate=F)+
  
  #facet_wrap(.~texture)+
  xlab ("tension, kPa (log scale)")+
  ylab ("percent saturation")+
  scale_x_continuous(trans = scales::log10_trans(), labels = scales::comma, 
                     sec.axis = sec_axis(~ .^-1 * 300, name = "pore size (um)", labels = scales::comma))+
  geom_hline(yintercept = 5, size=0.5, color = "grey80")+
  geom_hline(yintercept = 35, size=0.5, color = "grey80")+
  geom_hline(yintercept = 50, size=0.5, color = "grey80")+
  geom_hline(yintercept = 75, size=0.5, color = "grey80")+
  theme_kp()+
  theme(panel.grid = element_blank())



#

##    ## ggplot with old drying curve ----
      ##    
      ##    hyprop %>% 
      ##      mutate(texture = recode(soiltype, "Soil (sandy clay loam)"= "SCL" ,
      ##                              "Soil + Sand"="SL")) %>% 
      ##      filter(treatment=="Drying") %>% 
      ##      ggplot(aes(x = kPa, y = perc_sat))+
      ##      geom_path(color = "red")+
      ##      geom_path(data = wrc_processed %>% filter(treatment=="wetting"), color = "blue")+
      ##      facet_wrap(~texture)+
      ##      scale_x_log10(labels = scales::comma)+
      ##      theme_kp()
      ##      
      ##    a = tibble(~"sat", ~"kPa", ~texture,
      ##               100, 0.10, "SL",
      ##               100, 0.22,"SL",
      ##               75, 32.43,"SL",
      ##               50, 123.59,"SL",
      ##               35, 374.11,"SL",
      ##               5, 125314.12,"SL",
      ##               100, 0.10, "SCL",
      ##               75, 6.46,"SCL",
      ##               50, 30.97,"SCL",
      ##               35, 98.17,"SCL",
      ##               5, 54575.79, "SCL"
      ##               
      ##    )



# outputs -----------------------------------------------------------------

write.csv(wrc_processed, "data/processed/wrc.csv", row.names = F)


## ----

# water release -----------------------------------------------------------

## determine the volume of water released with successive increase in suction
wrc_processed = read.csv("data/processed/wrc.csv")

          # release = 
          #   wrc_processed %>% 
          #   group_by(texture, treatment) %>% 
          #   mutate(Diff = vol_water_perc - lag(vol_water_perc))


## SCL-drying

release_scl_drying = 
  wrc_processed %>% 
  select(vol_water_perc, treatment, texture, kPa) %>% 
  # keep only the SCL drying data
  filter(treatment %in% "drying" & texture %in% "SCL") %>% 
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
  arrange(desc(pore_um))

release_scl_drying_diff = 
  release_scl_drying %>% 
  # calculate sequential loss of water (lag)
  mutate(Diff = (vol_water_perc - lag(vol_water_perc))*-1) %>% 
  na.omit() %>% 
  add_row(texture="SCL", treatment="drying", 
          Diff = min(release_scl_drying$vol_water_perc),
          start = min(release_scl_drying$start),
          stop = min(release_scl_drying$stop)) %>% 
  mutate(Diff_perc = round((Diff/max(vol_water_perc, na.rm = TRUE))*100,2))
  # ungroup() %>% 
  # summarize(total = sum(Diff))

        release_scl_drying_diff %>% na.omit() %>% 
          ggplot()+
          geom_point(aes(x = pore_um, y = Diff))

release_scl_drying_summary  = 
  release_scl_drying_diff %>% 
  group_by(start, stop, treatment, texture) %>% 
  summarize(vol_water = sum(Diff)) 

release_scl_drying_bins = 
  release_scl_drying_summary %>% 
  ungroup() %>% 
  arrange(desc(stop)) #%>% 
  mutate(bins = if_else(stop<=100, stop, 3000)) %>% 
  group_by(treatment, texture, bins) %>% 
  dplyr::summarise(vol_water_perc = sum(vol_water))


ggplot(release_scl_drying_bins, aes(x = stop, y = vol_water))+
  geom_point()+
  scale_x_continuous(trans = "log10")


## drying

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

release_drying_diff2 %>%  
  ggplot()+
  geom_point(aes(x = pore_um, y = Diff))

release_drying_summary  = 
  release_drying_diff2 %>% 
  group_by(start, stop, treatment, texture) %>% 
  summarize(Diff = sum(Diff), # cm3
            Diff_perc = sum(Diff_perc)) 

release_drying_bins = 
  release_drying_summary %>% 
  ungroup() %>% 
  arrange(desc(stop)) %>% 
  mutate(bins = if_else(stop<=100, stop, 3000)) %>% 
  group_by(treatment, texture, bins) %>% 
  dplyr::summarise(vol_water_cm3 = sum(Diff),
                   vol_water_perc = sum(Diff_perc))

release_drying_bins %>% 
  ggplot(aes(x = reorder(as.character(bins), bins), y = vol_water_cm3, color = texture))+
  geom_point(size=3.5)+
  labs(x = "pore size class, upper limit (um)",
       y = "volume of pores in size class (cm3)")+
  scale_color_manual(values = soilpalettes::soil_palette("eutrostox",2))+
  theme_kp()+
  NULL

release_drying_diff2 %>% 
  mutate(mask = if_else(Diff>5, "large", "small")) %>% 
  ggplot(aes(x = pore_um, y = Diff, color = texture))+
  geom_point()+
  labs(x = "pore size (um)",
       y = "volume of pores (cm3)")+
  scale_color_manual(values = soilpalettes::soil_palette("eutrostox",2))+
  #facet_grid(mask~., scales = "free_y")+
  scale_y_log10(breaks=c(0.1, 0.2, 0.5, 1, 5, 10))+
  theme_kp()+
  theme(panel.grid.minor = element_blank())+
  NULL

release_drying_summary %>% 
  #mutate(mask = if_else(Diff>5, "large", "small")) %>% 
  ggplot(aes(x = stop, y = Diff, color = texture))+
  geom_point()+
  labs(x = "pore size (um)",
       y = "volume of pores (cm3)",
       subtitle = "pore size in 10 um bins")+
  scale_color_manual(values = soilpalettes::soil_palette("eutrostox",2))+
  #facet_grid(mask~., scales = "free_y")+
  scale_y_log10(breaks=c(0.1, 0.2, 0.5, 1, 5, 10))+
  scale_x_log10()+
  theme_kp()+
  theme(panel.grid.minor = element_blank())+
  NULL

  



