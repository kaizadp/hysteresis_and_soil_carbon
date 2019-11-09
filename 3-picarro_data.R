# 3-clean_picarro_data.R

clean_picarro_data <- function(prd) {
  message("Welcome to clean_picarro_data")
  
  prd %>% 
    clean_data(tz = "UTC") %>% 
    assign_sample_numbers()
}


compute_fluxes <- function(pd) {
  message("Welcome to compute_fluxes")
  
}
