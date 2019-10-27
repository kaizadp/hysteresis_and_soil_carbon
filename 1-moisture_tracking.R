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

# create a function that combines all the data needed for the weight/moisture calculation
  # 1. core key
  # 2. initial core weights, including dry weight 
  # 3. mass tracking file
read_massdata <- function(fqfn) {
  ca <- readxl::read_excel("data/Core_key.xlsx") %>% 
    dplyr::select(1:7)
  
  dry <- read_excel("data/Core_weights.xlsx", sheet = "initial") %>% 
    dplyr::select(Core, EmptyWt_g, DryWt_g)
  
 readxl::read_excel("data/Core_weights.xlsx", sheet = "Mass_tracking") %>% 
    filter(!is.na(Site), Site != "AMB", Core != "0") %>% # remove unnecessary crap
    left_join(ca, by = "Core") %>% 
    left_join(dry, by = "Core") %>% 
    filter(is.na(skip)) %>% # exclude the rows as needed
   # dplyr::select(Core, Stop_datetime, Seq.Program, Core_assignment, EmptyWt_g, DryWt_g, Mass_g, Moisture) %>% 
    dplyr::mutate(Stop_datetime = as.POSIXct(strptime(Stop_datetime,format = "%m/%d/%Y %H:%M")), #f-ing datetime
# calculate moisture content for each core
           DryWt_g = round(DryWt_g,2),
           MoistWt_g = Mass_g - EmptyWt_g,
           Water_g = MoistWt_g - DryWt_g,
           Moisture_perc = round(((Water_g/DryWt_g)*100),2))
}

plan <- drake_plan(
  massdata_file = "data/Core_weights.xlsx",
  massdata = read_massdata(massdata_file),
  
  # README file and diagnostics
  moisture = rmarkdown::render(
    knitr_in("1b-moisture_markdown.Rmd"),
    output_file = file_out("1b-moisture_markdown.md"),
    quiet = TRUE)
)


a=readd(massdata)








