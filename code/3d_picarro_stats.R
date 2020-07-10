# HYSTERESIS AND SOIL CARBON
# picarro_stats
# Kaizad F. Patel
# 2020

## this script will use processed Picarro data and calculate statistics.

# 1. load packages and files ----
source("0-hysteresis_packages.R")
fluxes = read.csv("data/processed/picarro_fluxes.csv", stringsAsFactors = F)
meanfluxes = read.csv("data/processed/picarro_meanfluxes.csv", stringsAsFactors = F)


#

# 2. overall anova ----
# test the effect of treatment, sat_level, texture on CO2 flux

aov1 = aov(flux_co2_nmol_g_s ~ treatment*texture*sat_level, data = fluxes)
summary(aov1)

aov2 = aov(flux_co2_nmol_gC_s ~ treatment*texture*sat_level, data = fluxes)
summary(aov2)

#

# 3. anova ----
# create anova function 
fit_anova <- function(dat) {
  a <-anova(lm(flux_co2_nmol_gC_s~treatment, data = dat))
  #create a tibble with one column for each treatment
  # column 4 has the pvalue
  t = tibble(pval = a$`Pr(>F)`[1])
  # we need to convert significant p values to asterisks
  t %>% 
    # conditionally replace all significant pvalues (p<0.05) with asterisks and the rest remain blank
    dplyr::mutate(p = if_else(pval<0.05, "*","")) %>% 
    # remove the pval column
    dplyr::select(-pval) %>% 
    dplyr::mutate(treatment = "Drying")->
    # spread the p (asterisks) column bnack into the three columns
    # spread(trt, p)  ->
    t
}

# apply this to `fluxes`
fluxes_anova = 
  fluxes %>% 
  filter(!is.na(sat_level)) %>% 
  group_by(texture, sat_level) %>% 
  do(fit_anova(.))
  #melt(id = c("site","Class"), value.name = "dunnett", variable.name = "treatment")-> #gather columns 4-7 (treatment levels)

fluxes_summary = 
  meanfluxes %>% 
  dplyr::select(-flux_co2_nmol_g_s) %>% 
  dplyr::mutate(flux_nmol_gC_s = paste(round(flux_co2_nmol_gC_s,3), "\u00b1", round(se_C,3))) %>% 
  left_join(fluxes_anova, by = c("texture", "sat_level", "treatment")) %>% 
  dplyr::mutate(flux_nmol_gC_s = paste(flux_nmol_gC_s, p),
                flux_nmol_gC_s = str_replace(flux_nmol_gC_s, "NA","")) %>% 
  dplyr::select(-p)
  
#

# 4. OUTPUT ----
write.csv(fluxes_summary, "data/processed/picarro_meanfluxes_summary.csv", row.names = F)
  






