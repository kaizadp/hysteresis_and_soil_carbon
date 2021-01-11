## SOIL CARBON-WATER HYSTERESIS
## KAIZAD F. PATEL

## 0-hysteresis_packages.R

## THIS SCRIPT CONTAINS PACKAGES, FUNCTIONS, AND FILE PATHS NEEDED TO RUN THE PROCESSING/ANALYSIS SCRIPTS IN THIS REPO.
## SOURCE THIS FILE IN THE SCRIPT YOU WANT TO RUN.


############### #
############### #

# PACKAGES ---------------------------------------------------------------
library(readxl)
library(lubridate)     # 1.6.0
library(luzlogr)       # 0.2.0
library(Rmisc)
library(data.table)
library(cowplot)
library(qwraps2)
library(knitr)
library(reshape2)
library(ggalt)
library(ggExtra)
library(stringi)
library(nlme)
library(car)
library(agricolae)
#library(googlesheets)
#library(gsheet)
library(multcomp)
#library(DescTools)

library(drake)
pkgconfig::set_config("drake::strings_in_dots" = "literals")

# My 'picarro.data' package isn't on CRAN (yet) so need to install it via:
# devtools::install_github("PNNL-TES/picarro.data")
library(picarro.data)

#devtools::install_github("miraKlein/ggbiplot")
library(ggbiplot)
library(tidyverse)

#devtools::install_github("kaizadp/soilpalettes")
library(soilpalettes)

# GGPLOT CUSTOMIZATIONS ---------------------------------------------------

# custom ggplot theme
theme_kp <- function() {  # this for all the elements common across plots
  theme_bw() %+replace%
    theme(legend.position = "top",
          legend.key=element_blank(),
          legend.title = element_blank(),
          legend.text = element_text(size = 12),
          legend.key.size = unit(1.5, 'lines'),
          legend.background = element_rect(colour = NA),
          panel.border = element_rect(color="black",size=1.5, fill = NA),
          
          plot.title = element_text(hjust = 0.05, size = 14),
          axis.text = element_text(size = 12, color = "black"),
          axis.title = element_text(size = 14, face = "bold", color = "black"),
          
          # formatting for facets
          panel.background = element_blank(),
          strip.background = element_rect(colour="white", fill="white"), #facet formatting
          panel.spacing.x = unit(1.5, "lines"), #facet spacing for x axis
          panel.spacing.y = unit(1.5, "lines"), #facet spacing for x axis
          strip.text.x = element_text(size=12, face="bold"), #facet labels
          strip.text.y = element_text(size=12, face="bold", angle = 270) #facet labels
    )
}

# custom ggplot function for Van Krevelen plots
gg_vankrev <- function(data,mapping){
  ggplot(data,mapping) +
    # plot points
    geom_point(size=2.5, alpha = 0.2) + # set size and transparency
    # axis labels
    ylab("H/C") +
    xlab("O/C") +
    # axis limits
    xlim(0,1.25) +
    ylim(0,2.5) +
    # add boundary lines for Van Krevelen regions
    geom_segment(x = 0.0, y = 1.5, xend = 1.2, yend = 1.5,color="black",linetype="longdash") +
    geom_segment(x = 0.0, y = 0.7, xend = 1.2, yend = 0.4,color="black",linetype="longdash") +
    geom_segment(x = 0.0, y = 1.06, xend = 1.2, yend = 0.51,color="black",linetype="longdash") +
    #geom_segment(x = 0.0, y = 1.5, xend = 1.2, yend = 1.5,color="black",linetype="longdash") +
    #geom_segment(x = 0.0, y = 2, xend = 1.2, yend = 2,color="black",linetype="longdash") +
    #geom_segment(x = 0.0, y = 1, xend = 1.2, yend = 0.75,color="black",linetype="longdash") +
    #geom_segment(x = 0.0, y = 0.8, xend = 1.2, yend = 0.8,color="black",linetype="longdash")+
    guides(colour = guide_legend(override.aes = list(alpha=1)))
  
}

## to make the Van Krevelen plot:
# replace the initial `ggplot` function with `gg_vankrev` and use as normal

# FILE PATHS -------------------------------------------------------------------
## CREATE OUTPUT FILES
COREKEY = "data/processed/corekey.csv"
WSOC = "data/processed/wsoc.csv"


FTICR_LONG = "data/processed/fticr_longform.csv"
FTICR_META = "data/processed/fticr_meta.csv"
FTICR_META_HCOC = "data/processed/fticr_meta_hcoc.csv"
