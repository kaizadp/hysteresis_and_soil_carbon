# 3-clean_picarro_data.R

# This is just a thin wrapper around two calls to picarro.data package functions
clean_picarro_data <- function(prd) {
  message("Welcome to clean_picarro_data")
  
  prd %>% 
    clean_data(tz = "UTC") %>% 
    assign_sample_numbers()
}

# Match the Picarro data (pd) with associated entries in the valve_key file.
# We do this by finding rows in pd that have the same valve number and who timestamps
# fall within the range specified in the valve_key
match_picarro_data <- function(pd, valve_key) {
  message("Welcome to match_picarro_data")
  if(is.null(pd)) return(NULL)
  
  pd_match_count <- rep(0L, nrow(pd))
  valve_key_match_count <- rep(0L, nrow(valve_key))
  
  results <- list()
  for(i in seq_len(nrow(valve_key))) {
    # find matches based on timestamp
    matches <- with(pd, DATETIME >= valve_key$Start_datetime[i] & 
                    DATETIME <= valve_key$Stop_datetime[i] &
                    MPVPosition == valve_key$Valve[i])
    
    # update match count for each record in each dataset
    pd_match_count[matches] <- pd_match_count[matches] + 1
    valve_key_match_count[i] <- sum(matches)
    
    # take those records from the Picarro data, record core, save
    pd[matches,] %>% 
      mutate(Core = valve_key$Core[i]) ->
      results[[i]]
  }
  
  # Return the Picarro data with new 'Core' column, and counts of how many times each
  # data row was matched (should be 1) and how many rows each valve_key entry matched
  list(pd = bind_rows(results), pmc = pd_match_count, vkmc = valve_key_match_count)
}

compute_fluxes <- function(pd) {
  message("Welcome to compute_fluxes")
  
}

