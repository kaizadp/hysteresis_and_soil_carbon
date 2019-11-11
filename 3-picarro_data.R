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

# Check for problems in the match process
qc_match <- function(p_clean, p_clean_matched, valve_key, p_match_count, valve_key_match_count) {
  vkmc <- sum(valve_key_match_count > 0)
  message(vkmc, " of ", length(valve_key_match_count), " valve key entries were matched")
  if(any(valve_key_match_count == 0)) {
    warning("Some valve key entries were not matched")
  }
  message(sum(p_match_count > 0), " of ", length(p_match_count), " Picarro data entries were matched")
  pmc1 <- sum(p_match_count > 1)
  if(pmc1) {
    warning(pmc1, " Picarro data entries were matched more than once")
  }
  
  p <- ggplot(p_clean, aes(DATETIME, MPVPosition, color = p_match_count)) + geom_point()
  ggsave("outputs/qc_match.pdf", plot = p)
}

# Plot concentrations
qc_concentrations <- function(p_clean_matched, valve_key) {
  p_co2 <- ggplot(p_clean_matched, aes(Elapsed_seconds, CO2_dry, group = Sample_number)) + 
    geom_line(alpha = 0.5) + 
    facet_wrap(~Core, scales = "free_y") +
    theme(axis.text.y = element_blank(), strip.text = element_text(size = 6))
  ggsave("outputs/qc_co2.pdf", plot = p_co2, height = 8, width = 8)
  
  p_ch4 <- ggplot(p_clean_matched, aes(Elapsed_seconds, CH4_dry, group = Sample_number)) + 
    geom_line(alpha = 0.5) + 
    facet_wrap(~Core, scales = "free_y") +
    theme(axis.text.y = element_blank(), strip.text = element_text(size = 6))
  ggsave("outputs/qc_ch4.pdf", plot = p_ch4)
}

compute_fluxes <- function(pd) {
  message("Welcome to compute_fluxes")
  
}

