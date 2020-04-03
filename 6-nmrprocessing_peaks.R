
source("0-hysteresis_packages.R")


library(readxl)
library(readr)
library(tidyverse)
library(dplyr)
library(ggplot2)
library(data.table)

# PART I. SETTING UP THE PARAMETERS ----
## 1. set up bins ----

## choose which set of BINS SET to use
cat("ACTION: choose correct value of BINSET
      a.> Clemente2012
      b.> Lynch2019
  type this into the code
  e.g.: BINSET = [quot]Clemente2012[quot]")

BINSET = "Clemente2012"

bins = read_csv("nmr_bins.csv")
bins2 = 
  bins %>% 
  # here we select only the BINSET we chose above
  dplyr::select(group,startstop,BINSET) %>% 
  na.omit %>% 
  spread(startstop,BINSET)


#
## 2. bins for water and DMSO solvent ----
WATER_start = 3
WATER_stop = 4

DMSO_start = 2.25
DMSO_stop = 2.75



## 3. spectra plot parameters ----
gg_nmr = 
  ggplot()+
  geom_rect(data=bins2, aes(xmin=start, xmax=stop, ymin=-Inf, ymax=+Inf, fill=group), color="grey70",alpha=0.1)+
  scale_x_reverse(limits = c(10,0))+
  xlab("shift, ppm")+
  ylab("intensity")+
  theme_bw() %+replace%
  theme(legend.position = "right",
        legend.key=element_blank(),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.key.size = unit(1.5, 'lines'),
        panel.border = element_rect(color="black",size=1.5, fill = NA),
        
        plot.title = element_text(hjust = 0.05, size = 14),
        axis.text = element_text(size = 14, color = "black"),
        axis.title = element_text(size = 14, face = "bold", color = "black"),
        
        # formatting for facets
        panel.background = element_blank(),
        strip.background = element_rect(colour="white", fill="white"), #facet formatting
        panel.spacing.x = unit(1.5, "lines"), #facet spacing for x axis
        panel.spacing.y = unit(1.5, "lines"), #facet spacing for x axis
        strip.text.x = element_text(size=12, face="bold"), #facet labels
        strip.text.y = element_text(size=12, face="bold", angle = 270) #facet labels
  )

#

# PART II. NMR spectra ----

# import all .csv files in the target folder 
# since MestreNova splits the table into multiple columns, we do this 2 times and then combine
# fml
## 1. import and process NMR peak data ----
filePaths <- list.files(path = "data/nmr_peaks/",pattern = "*.csv", full.names = TRUE)

spectra_temp1 <- do.call(rbind, lapply(filePaths, function(path) {
# the files are tab-delimited, so read.csv will not work. import using read.table
# there is no header. so create new column names
# then add a new column `source` to denote the file name
# select columns 2-9 now and then 11-18 in the next iteration  
    df <- fread(path, header=TRUE, select = c(2:9))
    df[["source"]] <- rep(path, nrow(df))
    df}))

spectra_temp2 <- do.call(rbind, lapply(filePaths, function(path) {
  # the files are tab-delimited, so read.csv will not work. import using read.table
  # there is no header. so create new column names
  # then add a new column `source` to denote the file name
  df <- fread(path, header=TRUE, select = c(11:18))
  df[["source"]] <- rep(path, nrow(df))
  df}))

# now combine both files
spectra = rbind(spectra_temp1, spectra_temp2) %>% 
# make the columns numeric
  dplyr::mutate(ppm = as.numeric(ppm),
                Intensity = as.numeric(Intensity),
                Width = as.numeric(Width),
                Area = as.numeric(Area)) %>% 
# keep only 0-10 ppm
  filter(ppm>=0&ppm<=10) %>% 
# remove solvent regions
   filter(!(ppm>2&ppm<4.2)) %>% 
  filter(!is.na(ppm)) %>% 
# the source column has the entire path, including directories
# delete the unnecessary strings
  dplyr::mutate(source = str_replace_all(source,"data/nmr_peaks//",""),
                source = str_replace_all(source,".csv","")) %>% 
  dplyr::rename(Core = source)

#

## 2. merge the processed data with the sample key ----

corekey = read.csv(COREKEY) %>% 
  dplyr::mutate(Core = as.character(Core))

spectra2 = 
  spectra %>% 
  left_join(corekey, by = "Core") %>% 
  dplyr::select(Core, soil_type, treatment, perc_sat,
                ppm, Area)

### OUTPUT


###############################################
###############################################

# because the peaks are split into two columns, we need to combine them
# first, create two temp files, one for each set
# then, combine below

## spectra_temp1 = 
##   spectra %>% 
##   dplyr::select(source, ppm, Intensity, Area) 
## spectra_temp2 = 
##   spectra %>% 
##   dplyr::select(source, ppm.1, Intensity.1, Area.1) %>% 
##   rename(ppm = ppm.1,
##          Intensity = Intensity.1,
##          Area = Area.1)
## 
## ## CLEANING
## spectra2 = 
##   spectra_temp1 %>% 
##   rbind(spectra_temp2) %>% 
## # retain only values 0-10ppm
##   filter(ppm>=0&ppm<=10) %>% 
## # remove water and DMSO regions
##   filter(!(ppm>DMSO_start&ppm<WATER_stop)) %>%  
##   filter(!(ppm>DMSO_start&ppm<DMSO_stop))
##   
