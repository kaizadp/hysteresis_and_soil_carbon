source("0-hysteresis_packages.R")
source("7a-nmr_spectra_setup.R")


# PART II. NMR spectra ----
## 1. import ----
# import all .csv files in the target folder 

filePaths <- list.files(path = "data/nmr_spectra",pattern = "*.csv", full.names = TRUE)

spectra <- do.call(rbind, lapply(filePaths, function(path) {
  # the files are tab-delimited, so read.csv will not work. import using read.table
  # there is no header. so create new column names
  # then add a new column `source` to denote the file name
  df <- read.table(path, header=FALSE, col.names = c("ppm", "intensity"))
  df[["source"]] <- rep(path, nrow(df))
  df}))


## 2. CLEANING ----
corekey = read.csv(COREKEY)
key = 
  corekey %>% 
  dplyr::select(Core, treatment, Core_assignment, perc_sat, sat_level,texture, soil_type) %>% 
  dplyr::mutate(Core = as.character(Core))

spectra2 = 
  spectra %>% 
  # retain only values 0-10ppm
  filter(ppm>=0&ppm<=10) %>% 
  # the source column has the entire path, including directories
  # delete the unnecessary strings
  dplyr::mutate(source = str_replace_all(source,"data/nmr_spectra/",""),
                source = str_replace_all(source,".csv","")) %>% 
  dplyr::rename(Core = source) %>% 
  left_join(key, by = "Core") 

# OUTPUT ----
crunch::write.csv.gz(spectra2, "data/processed/nmr_spectra.csv.gz", na = "")
#

# PART III: PLOTTING THE SPECTRA ----
## since we created the base gg_nmr earlier, we only need to add a single layer for the geom_path spectra


