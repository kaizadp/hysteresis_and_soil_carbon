
## Functions
# Kaizad F. Patel

## packages ####
library(readxl)
library(ggplot2)       # 2.1.0
library(readr)         # 1.0.0
library(lubridate)     # 1.6.0
library(stringr)       # 1.1.0
library(luzlogr)       # 0.2.0
library(tidyr)
library(readr)
library(Rmisc)
library(ggplot2)
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
library(googlesheets)
library(gsheet)
library(multcomp)
library(DescTools)
library(dplyr)         

library(drake)
pkgconfig::set_config("drake::strings_in_dots" = "literals")
library(googlesheets)
library(readxl)
library(tidyr)
library(dplyr)

# My 'picarro.data' package isn't on CRAN (yet) so need to install it via:
# devtools::install_github("PNNL-TES/picarro.data")
library(picarro.data)

# custom ggplot theme
theme_kp <- function() {  # this for all the elements common across plots
  theme_bw() %+replace%
    theme(legend.position = "top",
          legend.key=element_blank(),
          legend.title = element_blank(),
          legend.text = element_text(size = 12),
          legend.key.size = unit(1.5, 'lines'),
          panel.border = element_rect(color="black",size=1.5, fill = NA),
          
          plot.title = element_text(hjust = 0.05, size = 14),
          axis.text = element_text(size = 14, face = "bold", color = "black"),
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
    geom_point(size=2, alpha = 0.4) + # set size and transparency
    # axis labels
    ylab("H/C") +
    xlab("O/C") +
    # axis limits
    xlim(0,1.25) +
    ylim(0,2.5) +
    # add boundary lines for Van Krevelen regions
    geom_segment(x = 0.0, y = 1.5, xend = 1.2, yend = 1.5,color="black",linetype="longdash") +
    geom_segment(x = 0.0, y = 2, xend = 1.2, yend = 2,color="black",linetype="longdash") +
    geom_segment(x = 0.0, y = 1, xend = 1.2, yend = 0.75,color="black",linetype="longdash") +
    geom_segment(x = 0.0, y = 0.7, xend = 1.2, yend = 0.5,color="black",linetype="longdash")
}

## to make the Van Krevelen plot:
# replace the initial `ggplot` function with `gg_vankrev` and use as normal

## CREATE OUTPUT FILES

source("1-moisture_tracking.R")
source("3-picarro_data.R")

library(drake)

plan <- drake_plan(
  # Metadata
  core_key = read_core_key(file_in("data/Core_key.xlsx")),
  core_dry_weights = read_core_dryweights(file_in("data/Core_weights.xlsx"), sheet = "initial"),
  core_masses = read_core_masses(file_in("data/Core_weights.xlsx"),
                                  sheet = "Mass_tracking", core_key, core_dry_weights),
  valve_key = filter(core_masses, Seq.Program == "CPCRW_SFDec2018.seq"),

  # Picarro data
  # Using the 'trigger' argument below means we only re-read the Picarro raw
  # data when necessary, i.e. when the files change
  picarro_raw = target(process_directory("data/picarro_data/"),
                       trigger = trigger(change = list.files("data/picarro_data/", pattern = "dat$", recursive = TRUE))),
  picarro_clean = clean_picarro_data(picarro_raw),
  
  # Match Picarro data with the valve key data
  pcm = match_picarro_data(picarro_clean, valve_key),
  picarro_clean_matched = pcm$pd,
  picarro_match_count = pcm$pmc,
  valve_key_match_count = pcm$vkmc,
  
  qc = qc_match(picarro_clean, picarro_clean_matched, valve_key, picarro_match_count, valve_key_match_count),
  
  picarro_fluxes = compute_fluxes(picarro_clean_matched)
)
message("Now type make(plan)")
