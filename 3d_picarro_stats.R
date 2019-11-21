source("3c-picarro_output_NODRAKE.R")

make(plan)

cum_flux = readd(cum_flux)
gf = readd(gf)
mean_percsat = readd(mean_percsat)


gf %>% 
  dplyr::select(Core, DATETIME, Core_assignment, soil_type, moisture_lvl, trt,
                flux_co2_umol_g_s, flux_co2_umol_gC_s) %>% 
  dplyr::mutate(flux_co2_nmol_g_s = flux_co2_umol_g_s*1000,
                flux_co2_nmol_gC_s = flux_co2_umol_gC_s*1000)->
  gf_select


gf_select %>% 
  group_by(moisture_lvl, trt, soil_type) %>% 
  dplyr::summarise(flux_gC = round(mean(flux_co2_nmol_gC_s),3),
                   se = round(sd(flux_co2_nmol_gC_s)/sqrt(n()),3),
                   mean_se = paste(flux_gC,"\u00B1",se)) %>% 
  ungroup %>% 
  dplyr::mutate(trt = if_else(moisture_lvl=="fm","W",trt))->temp

### anova
fit_anova <- function(dat) {
  a <-anova(lm(flux_co2_nmol_gC_s~trt, data = dat))
  #create a tibble with one column for each treatment
  # column 4 has the pvalue
  t = tibble(pval = a$`Pr(>F)`[1])
  # we need to convert significant p values to asterisks
  t %>% 
    # conditionally replace all significant pvalues (p<0.05) with asterisks and the rest remain blank
    dplyr::mutate(p = if_else(pval<0.05, "*","")) %>% 
    # remove the pval column
    dplyr::select(-pval) %>% 
    dplyr::mutate(trt = "D")->
    # spread the p (asterisks) column bnack into the three columns
    # spread(trt, p)  ->
    t
}

gf_select[!is.na(gf_select$trt),] %>% 
  group_by(moisture_lvl, soil_type) %>% 
  do(fit_anova(.))->
  #melt(id = c("site","Class"), value.name = "dunnett", variable.name = "treatment")-> #gather columns 4-7 (treatment levels)
  anova_p

temp %>% 
  ungroup %>% 
  left_join(anova_p, by = c("moisture_lvl", "trt","soil_type")) %>% 
  dplyr::mutate(summary = paste(mean_se, p)) %>% 
  dplyr::mutate(var = paste(soil_type,trt)) %>% 
  dplyr::select(var, moisture_lvl, summary) %>% 
  spread(var, summary)  ->gf_summary
