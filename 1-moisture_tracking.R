# HYSTERESIS AND SOIL C
# Kaizad F. Patel 
# Oct. 25, 2019

# tracking moisture content in soil cores
### taken from BBL's script TESDrydown/drake_plan.R

# drake plan

library(drake)
pkgconfig::set_config("drake::strings_in_dots" = "literals")
library(ggplot2)
theme_set(theme_bw())
library(googlesheets)
library(readxl)
library(tidyr)
library(dplyr)

      # download_massdata <- function(fqfn) {
      #   readxl::read_xlsx("Core_key.xlsx") %>% 
      #     filter(is.na(skip)) %>% 
      #     select(1:6)
      # }

read_massdata <- function(fqfn) {
  ca <- readxl::read_excel("data/Core_key.xlsx") %>% 
    select(1:7)
  
  dry <- read_excel(fqfn, sheet = "initial") %>% 
    select(Core, EmptyWt_g, DryWt_g)
  
  mass = readxl::read_excel(fqfn, sheet = "Mass_tracking") %>% 
    filter(!is.na(Site), Site != "AMB", Core != "0") %>% 
    left_join(ca, by = "Core") %>% 
    left_join(dry, by = "Core") %>% 
    filter(is.na(skip)) %>% 
    select(Core, Start_datetime, Seq.Program, Core_assignment, EmptyWt_g, DryWt_g, Mass_g, Moisture) %>% 
    mutate(Start_datetime = as.POSIXct(strptime(Start_datetime,format = "%m/%d/%Y %H:%M")),
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

