# 3Soils
# 4-fticr_abundance 
# Kaizad F. Patel
# October 2019

# this file takes the processed fticr files from script 3 and calculates peaks and abundances 

source("0-packages.R")

# ------------------------------------------------------- ----

# FILES ----
## use the raw-long files for relative abundance only
## use the long files for peaks

soil_meta = read.csv(FTICR_SOIL_META)# <- "fticr/fticr_soil_meta.csv"
#FTICR_SOIL_META_HCOC <- "fticr/soil_meta_hcoc.csv"
soil_raw_long = read.csv(FTICR_SOIL_RAW_LONG)# <- "fticr/fticr_soil_raw_longform.csv"
soil_long = read.csv(FTICR_SOIL_LONG)# <- "fticr/fticr_soil_longform.csv"

pore_meta = read.csv(FTICR_PORE_META)# <- "fticr/fticr_pore_meta.csv"
pore_long = read.csv(FTICR_PORE_LONG)# <- "fticr/fticr_pore_longform.csv"
pore_raw_long = read.csv(FTICR_PORE_RAW_LONG)# <- "fticr/fticr_pore_raw_longform.csv"

# ------------------------------------------------------- ----

# PART I: SOIL PEAKS ----

soil_long %>% 
  group_by(site,treatment,Class) %>% 
  dplyr::summarize(peaks = n()) %>% # get count of each group/class for each tension-site-treatment
  group_by(site,treatment) %>% 
  dplyr::mutate(total = sum(peaks))%>%  # then create a new column for sum of all peaks for each tension-site-treatment
# we need to combine the total value into the existing groups column
  ungroup %>% 
  spread(Class,peaks) %>% # first, convert into wide-form, so each group is a column
  dplyr::select(-total,total) %>% # move total to the end
  gather(Class,peaks_count,AminoSugar:total)-> # combine all the groups+total into a single column
  fticr_soil_peaks


### OUTPUT 
write.csv(fticr_soil_peaks,FTICR_SOIL_PEAKS, row.names = FALSE)

# PART II: SOIL UNIQUE PEAKS ----
soil_long %>% 
  spread(treatment, intensity) %>% 
# add columns for new/lost molecules
  dplyr::mutate(drought2 = case_when(!is.na(drought)&is.na(baseline) ~ "new",
                                        is.na(drought)&!is.na(baseline) ~ "lost"),
                  fm2 = case_when(!is.na(`field moist`)&is.na(baseline) ~ "new",
                                        is.na(`field moist`)&!is.na(baseline) ~ "lost"),
                  saturation2 = case_when(!is.na(saturation)&is.na(baseline) ~ "new",
                                        is.na(saturation)&!is.na(baseline) ~ "lost")) %>% 
# add columns for unique peaks
  dplyr:: mutate(unique = case_when((drought2=="new" & is.na(fm2) & is.na(saturation2)) ~ "drought",
                                    (saturation2=="new" & is.na(fm2) & is.na(drought2)) ~ "saturation",
                                    (fm2=="new" & is.na(drought2) & is.na(saturation2)) ~ "field moist")) %>% 
  dplyr::select(-drought, -saturation, -baseline, -`field moist`,-`time zero saturation`)-> 
  soil_unique_peaks

### OUTPUT
write.csv(soil_unique_peaks,FTICR_SOIL_UNIQUE, row.names = FALSE)



# PART III: SOIL AROMATIC PEAKS ----
meta_aromatic <- soil_meta %>% 
  dplyr::select(Mass, AI_Mod)
  
soil_raw_long %>%
  left_join(meta_aromatic, by = "Mass") %>% 
# create a column designating aromatic  vs. aliphatic
# aromatic == AI_Mod > 0.5, aliphatic == 1.5 < HC < 2.0
# see Bailey et al. 2017 SBB, Chasse et al. 2015 for references
  dplyr::mutate(aromatic = case_when(AI_Mod>0.5 ~ "aromatic", 
                                     (HC<2.0 & HC>1.5) ~ "aliphatic"))  ->
  soil_aromatic

soil_aromatic %>% 
  drop_na %>% 
  group_by(site, treatment, core, aromatic) %>% 
  dplyr::summarize(counts = n())->
  soil_aromatic_counts


## b. stats for aromatic peaks (Dunnett's test) ----

fit_dunnett_aromatic_soil <- function(dat) {
  d <-DescTools::DunnettTest(counts~treatment, control = "time zero saturation", data = dat)
  #create a tibble with one column for each treatment
  # column 4 has the pvalue
  t = tibble(drought = d$`time zero saturation`["drought-time zero saturation",4], 
             saturation = d$`time zero saturation`["saturation-time zero saturation",4],
             `field moist` = d$`time zero saturation`["field moist-time zero saturation",4])
  # we need to convert significant p values to asterisks
  # since the values are in a single row, it is tricky
  t %>% 
    # first, gather all p-values into a single column, pval
    gather(trt, pval, 1:3) %>% 
    # conditionally replace all significant pvalues (p<0.05) with asterisks and the rest remain blank
    dplyr::mutate(p = if_else(pval<0.05, "*","")) %>% 
    # remove the pval column
    dplyr::select(-pval) %>% 
    # spread the p (asterisks) column bnack into the three columns
    spread(trt, p)  ->
    t
}
soil_aromatic_temp = 
  soil_aromatic_counts %>%
  filter(aromatic=="aromatic") %>% 
  group_by(site) %>% 
  do(fit_dunnett_aromatic_soil(.)) %>% 
  melt(id = c("site"), value.name = "dunnett", variable.name = "treatment")
soil_aromatic_summary = 
  soil_aromatic_counts %>%
  filter(aromatic=="aromatic") %>% 
  group_by(site, treatment) %>% 
  dplyr::summarise(counts_mean = as.integer(mean(counts)),
                   counts_se = sd(counts)/sqrt(n())) %>% 
  left_join(soil_aromatic_temp, by = c("site","treatment"), all.x=TRUE)

### OUTPUT
# write.csv(fticr_soil_aromatic_counts,"fticr_soil_aromatic_counts.csv")
write_csv(soil_aromatic_counts, FTICR_SOIL_AROMATIC)
write_csv(soil_aromatic_summary, FTICR_SOIL_AROMATIC_SUMMARY)
FTICR_SOIL_AROMATIC_SUMMARY = "fticr/soil_aromatic_summary.csv"

# ------------------------------------------------------- ----

# PART IV: SOIL RELATIVE ABUNDANCE ----
## step 1: create a summary table by group/treatment

soil_raw_long %>% 
  group_by(site, treatment,Class,core) %>% 
  dplyr::summarize(compounds = n()) %>% # sum all intensities for each Class
# now calculate relative abundance for each Class for each core
  group_by(site, treatment, core) %>% 
  dplyr::mutate(total = sum(compounds),
                relabund = (compounds/total)*100)->
  soil_relabund_temp

soil_relabund_temp%>% 
  # now summarize by treatment. combine cores
  ungroup %>% 
  dplyr::group_by(site, treatment, Class) %>% 
  dplyr::summarize(relabund2 = mean(relabund),
                   se = sd(relabund)/sqrt(n())) %>% 
  # create a column of relabund +/- se  
  dplyr::mutate(relabund = paste(round(relabund2,2),"\u00B1",round(se,2))) %>% 
  # we need to add a total column
  dplyr::mutate(total = 100) %>% 
  dplyr::select(-se) -> 
  soil_relabund



relabund_temp%>% 
# now summarize by treatment. combine cores
  ungroup %>% 
  dplyr::group_by(site, treatment, Class) %>% 
  dplyr::summarize(relabund2 = mean(relabund),
                   se = sd(relabund)/sqrt(n())) %>% 
# create a column of relabund +/- se  
  dplyr::mutate(relabund = paste(round(relabund2,2),"\u00B1",round(se,2))) %>% 
# we need to add a total column
  dplyr::mutate(total = 100) %>% 
  dplyr::select(-se,-relabund2) %>% 
# we need to bring the total column into the Class.
# so first spread the class column and then melt back together
  spread(Class, relabund) %>% 
  melt(id = c("site","treatment")) %>% 
  dplyr::rename(Class = variable,
                relabund= value)->
  soil_relabund2
# we will combine this file with the Dunnett test results below
  

## step 2: DUNNETT'S TEST 

fit_dunnett_relabund <- function(dat) {
  d <-DescTools::DunnettTest(relabund~treatment, control = "baseline", data = dat)
  #create a tibble with one column for each treatment
  # column 4 has the pvalue
  t = tibble(`drought` = d$`baseline`["drought-baseline",4], 
             `saturation` = d$`baseline`["saturation-baseline",4],
             `field moist` = d$`baseline`["field moist-baseline",4],
             `TZsaturation` = d$baseline["time zero saturation-baseline",4])
  # we need to convert significant p values to asterisks
  # since the values are in a single row, it is tricky
  t %>% 
    # first, gather all p-values into a single column, pval
    gather(trt, pval, 1:4) %>% 
    # conditionally replace all significant pvalues (p<0.05) with asterisks and the rest remain blank
    mutate(p = if_else(pval<0.05, "*","")) %>% 
    # remove the pval column
    dplyr::select(-pval) %>% 
    # spread the p (asterisks) column bnack into the three columns
    spread(trt, p)  ->
    t
}

relabund_temp[!relabund_temp$Class=="total",] %>% 
  group_by(site, Class) %>% 
  do(fit_dunnett_relabund(.)) %>% 
  melt(id = c("site","Class"), value.name = "dunnett", variable.name = "treatment")-> #gather columns 4-7 (treatment levels)
  soil_relabund_dunnett

## step 3: now merge this with `soil_relabund`

soil_relabund %>% 
  left_join(soil_relabund_dunnett,by = c("site","Class","treatment"), all.x = TRUE) %>% 
  replace(.,is.na(.),"") %>% 
  dplyr::mutate(relativeabundance = paste(relabund,dunnett)) %>% 
  dplyr::select(-relabund, -dunnett) ->
  fticr_soil_relativeabundance


#
      ## ## HSD. DONT DO ----
      ## fit_hsd_relabund <- function(dat) {
      ##   a <-aov(relabund ~ treatment, data = dat)
      ##   h <-HSD.test(a,"treatment")
      ##   #create a tibble with one column for each treatment
      ##   #the hsd results are row1 = drought, row2 = saturation, row3 = time zero saturation, row4 = field moist. hsd letters are in column 2
      ##   tibble(`drought` = h$groups["drought",2], 
      ##          `saturation` = h$groups["saturation",2],
      ##          `time zero saturation` = h$groups["time zero saturation",2],
      ##          `field moist` = h$groups["field moist",2],
      ##          `baseline` = h$groups["baseline",2])
      ## }
      ## 
      ## fticr_soil_relabundance_long[!fticr_soil_relabundance_long$group=="total",] %>% 
      ##   group_by(site, group) %>% 
      ##   do(fit_hsd_relabund(.))  ->
      ##   soil_relabund_hsd
      ## 
      ## soil_relabund_hsd %>% 
      ##   gather(treatment, hsd, 3:7)-> #gather columns 4-7 (treatment levels)
      ##   soil_relabund_hsd2
      ## 
      ## # now merge this with `fticr_soil_relabundance_summary`
      ## 
      ## fticr_soil_relabundance_summary2 = merge(fticr_soil_relabundance_summary, soil_relabund_hsd2, by = c("site","group","treatment"))
      ## 
      ## # combine hsd and values and thenremove unnecessary columns
      ## fticr_soil_relabundance_summary2 %>% 
      ##   mutate(relabund_hsd = paste(relativeabundance," ",hsd)) %>% 
      ##   select(-sd,-se,-ci,-hsd)->
      ##   fticr_soil_relabundance_summary2




### OUTPUT ----
write_csv(fticr_soil_relativeabundance, FTICR_SOIL_RELABUND)
#

# ------------------------------------------------------- ----
# ------------------------------------------------------- ----

# PART V: POREWATER PEAKS ----
pore_long %>% 
  group_by(tension,site,treatment,Class) %>% 
  dplyr::summarize(peaks = n()) %>% # get count of each group/class for each tension-site-treatment
  group_by(tension,site,treatment) %>% 
  dplyr::mutate(total = sum(peaks))%>%  # then create a new column for sum of all peaks for each tension-site-treatment
  # we need to combine the total value into the existing groups column
  ungroup %>% 
  spread(Class,peaks) %>% # first, convert into wide-form, so each group is a column
  dplyr::select(-total,total) %>% # move total to the end
  gather(Class,peaks_count,AminoSugar:total)-> # combine all the groups+total into a single column
  fticr_pore_peaks


### OUTPUT 
write_csv(fticr_pore_peaks,FTICR_PORE_PEAKS)

#
# PART VI: PORE UNIQUE PEAKS ----
pore_long %>% 
  spread(treatment, intensity) %>% 
  # add columns for new/lost molecules
  dplyr::mutate(drought2 = case_when(!is.na(drought)&is.na(`time zero saturation`) ~ "new",
                                     is.na(drought)&!is.na(`time zero saturation`) ~ "lost"),
                fm2 = case_when(!is.na(`field moist`)&is.na(`time zero saturation`) ~ "new",
                                is.na(`field moist`)&!is.na(`time zero saturation`) ~ "lost"),
                saturation2 = case_when(!is.na(saturation)&is.na(`time zero saturation`) ~ "new",
                                        is.na(saturation)&!is.na(`time zero saturation`) ~ "lost")) %>% 
  # add columns for unique peaks
  dplyr:: mutate(unique = case_when((drought2=="new" & is.na(fm2) & is.na(saturation2)) ~ "drought",
                                    (saturation2=="new" & is.na(fm2) & is.na(drought2)) ~ "saturation",
                                    (fm2=="new" & is.na(drought2) & is.na(saturation2)) ~ "field moist")) %>% 
  dplyr::select(-drought, -saturation, -`field moist`,-`time zero saturation`)-> 
  pore_unique_peaks

### OUTPUT
write.csv(pore_unique_peaks,FTICR_PORE_UNIQUE, row.names = FALSE)


#
# PART VII: PORE AROMATIC PEAKS ----
meta_aromatic <- pore_meta %>% 
  dplyr::select(Mass, AImod) %>% 
  dplyr::rename(AI_Mod = AImod)

pore_raw_long %>%
  left_join(meta_aromatic, by = "Mass") %>% 
  # create a column designating aromatic  vs. aliphatic
  # aromatic == AI_Mod > 0.5, aliphatic == 1.5 < HC < 2.0
  # see Bailey et al. 2017 SBB, Chasse et al. 2015 for references
  dplyr::mutate(aromatic = case_when(AI_Mod>0.5 ~ "aromatic", 
                                     (HC<2.0 & HC>1.5) ~ "aliphatic"))  ->
  pore_aromatic

pore_aromatic %>% 
  drop_na %>% 
  group_by(tension,site, treatment, core, aromatic) %>% 
  dplyr::summarize(counts = n())->
  pore_aromatic_counts

## b. stats for aromatic peaks (Dunnett's test) ----
fit_dunnett_aromatic_pore <- function(dat) {
  d <-DescTools::DunnettTest(counts~treatment, control = "time zero saturation", data = dat)
  #create a tibble with one column for each treatment
  # column 4 has the pvalue
  t = tibble(drought = d$`time zero saturation`["drought-time zero saturation",4], 
             saturation = d$`time zero saturation`["saturation-time zero saturation",4],
             `field moist` = d$`time zero saturation`["field moist-time zero saturation",4])
  # we need to convert significant p values to asterisks
  # since the values are in a single row, it is tricky
  t %>% 
    # first, gather all p-values into a single column, pval
    gather(trt, pval, 1:3) %>% 
    # conditionally replace all significant pvalues (p<0.05) with asterisks and the rest remain blank
    dplyr::mutate(p = if_else(pval<0.05, "*","")) %>% 
    # remove the pval column
    dplyr::select(-pval) %>% 
    # spread the p (asterisks) column bnack into the three columns
    spread(trt, p)  ->
    t
}
pore_aromatic_temp = 
  pore_aromatic_counts %>%
  filter(aromatic=="aromatic") %>% 
  group_by(site,tension) %>% 
  do(fit_dunnett_aromatic_pore(.)) %>% 
  melt(id = c("tension","site"), value.name = "dunnett", variable.name = "treatment")
pore_aromatic_summary = 
  pore_aromatic_counts %>%
  filter(aromatic=="aromatic") %>% 
  group_by(site, treatment, tension) %>% 
  dplyr::summarise(counts_mean = as.integer(mean(counts)),
                   counts_se = sd(counts)/sqrt(n())) %>% 
  left_join(pore_aromatic_temp, by = c("site","treatment","tension"), all.x=TRUE)
  

### OUTPUT
# write.csv(fticr_soil_aromatic_counts,"fticr_soil_aromatic_counts.csv")
write_csv(pore_aromatic_counts, FTICR_PORE_AROMATIC)
write_csv(pore_aromatic_summary, FTICR_PORE_AROMATIC_SUMMARY)
FTICR_PORE_AROMATIC_SUMMARY = "fticr/pore_aromatic_summary.csv"
#





# ------------------------------------------------------- ----

# PART IV: PORE RELATIVE ABUNDANCE ----
## step 1: create a summary table by group/treatment

pore_raw_long %>% 
  group_by(tension,site, treatment,Class,core) %>% 
  dplyr::summarize(compounds = n()) %>% # sum all COUNTS for each Class
  # now calculate relative abundance for each Class for each core
  group_by(tension,site, treatment, core) %>% 
  dplyr::mutate(total = sum(compounds),
                relabund = (compounds/total)*100)->
  relabund_temp

relabund_temp%>% 
  # now summarize by treatment. combine cores
  ungroup %>% 
  dplyr::group_by(tension,site, treatment, Class) %>% 
  dplyr::summarize(relabund2 = mean(relabund),
                   se = sd(relabund)/sqrt(n())) %>% 
  # create a column of relabund +/- se  
  dplyr::mutate(relabund = paste(round(relabund2,2),"\u00B1",round(se,2))) %>% 
  # we need to add a total column
  dplyr::mutate(total = 100) %>% 
  dplyr::select(-se) -> 
  pore_relabund
# we will combine this file with the Dunnett test results below


## step 2: DUNNETT'S TEST 

fit_dunnett_relabund <- function(dat) {
  d <-DescTools::DunnettTest(relabund~treatment, control = "time zero saturation", data = dat)
  #create a tibble with one column for each treatment
  # column 4 has the pvalue
  t = tibble(drought = d$`time zero saturation`["drought-time zero saturation",4], 
             saturation = d$`time zero saturation`["saturation-time zero saturation",4],
             `field moist` = d$`time zero saturation`["field moist-time zero saturation",4])
  # we need to convert significant p values to asterisks
  # since the values are in a single row, it is tricky
  t %>% 
    # first, gather all p-values into a single column, pval
    gather(trt, pval, 1:3) %>% 
    # conditionally replace all significant pvalues (p<0.05) with asterisks and the rest remain blank
    dplyr::mutate(p = if_else(pval<0.05, "*","")) %>% 
    # remove the pval column
    dplyr::select(-pval) %>% 
    # spread the p (asterisks) column bnack into the three columns
    spread(trt, p)  ->
    t
}

relabund_temp[!relabund_temp$Class=="Other",] %>% 
  ungroup %>% 
  dplyr::group_by(tension,site,Class) %>% 
  do(fit_dunnett_relabund(.)) %>% 
  melt(id = c("tension","site","Class"), value.name = "dunnett", variable.name = "treatment")-> #gather columns 4-7 (treatment levels)
  pore_relabund_dunnett

## step 3: now merge this with `soil_relabund`

pore_relabund %>% 
  left_join(pore_relabund_dunnett,by = c("tension","site","Class","treatment"), all.x = TRUE) %>% 
  replace(.,is.na(.),"") %>% 
  dplyr::mutate(relativeabundance = paste(relabund,dunnett)) %>% 
  dplyr::select(-relabund, -dunnett)->
  fticr_pore_relabundance


### OUTPUT
write.csv(fticr_pore_relabundance, FTICR_PORE_RELABUND)

# ------------------------------------------------------- ----

# PART V: SHANNON DIVERSITY ----
# Shannon diversity, H = - sum [p*ln(p)], where n = no. of individuals per species/total number of individuals
## a. for pores ----
pore_raw_long %>% 
  group_by(tension,site,treatment, core,Class) %>% 
  dplyr::summarize(n = n()) %>%
  ungroup %>% 
  group_by(tension,site,treatment,core) %>% 
  dplyr::mutate(total = sum(n),
                p = n/total,
                log = log(p),
                p_logp = p*log) %>% 
  dplyr::summarize(H1 = sum(p_logp),
                H = round(-1*H1, 2)) %>% 
  dplyr::select(-H1)->pore_shannon 

# summary stats for Shannon -- Dunnett Test 

fit_dunnett_shannon_pore <- function(dat) {
  d <-DescTools::DunnettTest(H~treatment, control = "time zero saturation", data = dat)
  #create a tibble with one column for each treatment
  # column 4 has the pvalue
  t = tibble(drought = d$`time zero saturation`["drought-time zero saturation",4], 
             saturation = d$`time zero saturation`["saturation-time zero saturation",4],
             `field moist` = d$`time zero saturation`["field moist-time zero saturation",4])
  # we need to convert significant p values to asterisks
  # since the values are in a single row, it is tricky
  t %>% 
    # first, gather all p-values into a single column, pval
    gather(trt, pval, 1:3) %>% 
    # conditionally replace all significant pvalues (p<0.05) with asterisks and the rest remain blank
    dplyr::mutate(p = if_else(pval<0.05, "*","")) %>% 
    # remove the pval column
    dplyr::select(-pval) %>% 
    # spread the p (asterisks) column bnack into the three columns
    spread(trt, p)  ->
    t
}
pore_shannon_temp = 
  pore_shannon %>%
  group_by(site,tension) %>% 
  do(fit_dunnett_shannon_pore(.)) %>% 
  melt(id = c("tension","site"), value.name = "dunnett", variable.name = "treatment")
pore_shannon_summary = 
  pore_shannon %>%
  group_by(site, treatment, tension) %>% 
  dplyr::summarise(H_mean = (mean(H)),
                   H_se = sd(H)/sqrt(n())) %>% 
  left_join(pore_shannon_temp, by = c("site","treatment","tension"), all.x=TRUE)


### OUTPUT
write.csv(pore_shannon, FTICR_PORE_DIVERSITY)
write.csv(pore_shannon_summary, "fticr/pore_diversity_summary.csv")

## b. for soil ----
soil_raw_long %>% 
  group_by(site,treatment, core,Class) %>% 
  dplyr::summarize(n = n()) %>%
  ungroup %>% 
  group_by(site,treatment,core) %>% 
  dplyr::mutate(total = sum(n),
                p = n/total,
                log = log(p),
                p_logp = p*log) %>% 
  dplyr::summarize(H1 = sum(p_logp),
                   H = round(-1*H1, 2)) %>% 
  dplyr::select(-H1)->soil_shannon 


fit_dunnett_shannon_soil <- function(dat) {
  d <-DescTools::DunnettTest(H~treatment, control = "baseline", data = dat)
  #create a tibble with one column for each treatment
  # column 4 has the pvalue
  t = tibble(drought = d$baseline["drought-baseline",4], 
             saturation = d$baseline["saturation-baseline",4],
             `field moist` = d$baseline["field moist-baseline",4])
  # we need to convert significant p values to asterisks
  # since the values are in a single row, it is tricky
  t %>% 
    # first, gather all p-values into a single column, pval
    gather(trt, pval, 1:3) %>% 
    # conditionally replace all significant pvalues (p<0.05) with asterisks and the rest remain blank
    dplyr::mutate(p = if_else(pval<0.05, "*","")) %>% 
    # remove the pval column
    dplyr::select(-pval) %>% 
    # spread the p (asterisks) column bnack into the three columns
    spread(trt, p)  ->
    t
}
soil_shannon_temp = 
  soil_shannon %>%
  group_by(site) %>% 
  do(fit_dunnett_shannon_soil(.)) %>% 
  melt(id = c("site"), value.name = "dunnett", variable.name = "treatment")
soil_shannon_summary = 
  soil_shannon %>%
  group_by(site, treatment) %>% 
  dplyr::summarise(H_mean = (mean(H)),
                   H_se = sd(H)/sqrt(n())) %>% 
  left_join(soil_shannon_temp, by = c("site","treatment"), all.x=TRUE)

### OUTPUT
write.csv(soil_shannon, "fticr/soil_diversity.csv")
write.csv(soil_shannon_summary, "fticr/soil_diversity_summary.csv")

#
# ------------------------------------------------------- ----

# PART VI: RELATIVE ABUNDANCE PCA ----
pore_relabund = read.csv(FTICR_PORE_RELABUND)# <- "fticr/fticr_pore_relabundance_groups2_hsd.csv"
soil_relabund = read.csv(FTICR_SOIL_RELABUND)# <- "fticr/fticr_soil_relabundance_hsd.csv"

## a. pores ----
## native SOM pca
pore_relabund_pca=
  relabund_temp %>% 
  ungroup %>% 
  dplyr::select(core,tension, site, treatment, Class, relabund) %>% 
  filter(treatment=="time zero saturation") %>% 
  spread(Class, relabund) %>% 
  replace(.,is.na(.),0) %>% 
  dplyr::select(-1)

pore_relabund_pca_num = 
  pore_relabund_pca %>% 
  dplyr::select(.,-(1:3))

pore_relabund_pca_grp = 
  pore_relabund_pca %>% 
  dplyr::select(.,(1:3)) %>% 
  dplyr::mutate(row = row_number())

pca = prcomp(pore_relabund_pca_num, scale. = T)
summary(pca)

ggbiplot(pca, obs.scale = 1, var.scale = 1, 
         groups = pore_relabund_pca_grp$site, ellipse = TRUE, circle = F,
         var.axes = TRUE)+
  geom_point(size=2,stroke=2, aes(shape = pore_relabund_pca_grp$tension, color = groups))+
  scale_shape_manual(values = c(1,4))

bray_distance = vegdist(pore_relabund_pca_num, method="euclidean")
principal_coordinates = pcoa(bray_distance)

pcoa_plot = data.frame(principal_coordinates$vectors[,])
pcoa_plot_merged = merge(pcoa_plot, pore_relabund_pca_grp, by="row.names")

####### Calculate percent variation explained by PC1, PC2

PC1 <- 100*(principal_coordinates$values$Eigenvalues[1]/sum(principal_coordinates$values$Eigenvalues))
PC2 <- 100*(principal_coordinates$values$Eigenvalues[2]/sum(principal_coordinates$values$Eigenvalues))
PC3 <- 100*(principal_coordinates$values$Eigenvalues[3]/sum(principal_coordinates$values$Eigenvalues))

###### Plot PCoA

ggplot(data=pcoa_plot_merged,aes(x=Axis.1,y=Axis.2,color=treatment, shape=site)) + 
  geom_point(size=4)+
  facet_grid(tension~site)+
  stat_ellipse()+
  theme_kp()+
  theme(legend.position = "right")+
  labs(x = paste("PC1 - Variation Explained", round(PC1,2),"%"), y = paste("PC2 - Variation Explained", round(PC2,2),"%"))


## treatment PCA: all pores

pore_relabund_pca=
  relabund_temp %>% 
  ungroup %>% 
  dplyr::select(core,tension, site, treatment, Class, relabund) %>% 
  #filter(treatment=="time zero saturation") %>% 
  spread(Class, relabund) %>% 
  replace(.,is.na(.),0) %>% 
  dplyr::select(-1)

pore_relabund_pca_num = 
  pore_relabund_pca %>% 
  dplyr::select(.,-(1:3))

pore_relabund_pca_grp = 
  pore_relabund_pca %>% 
  dplyr::select(.,(1:3)) %>% 
  dplyr::mutate(row = row_number())

pca = prcomp(pore_relabund_pca_num, scale. = T)
summary(pca)

ggbiplot(pca, obs.scale = 1, var.scale = 1, 
         groups = pore_relabund_pca_grp$site, ellipse = F, circle = F,
         var.axes = TRUE)+
  geom_point(size=2,stroke=2, aes(shape = pore_relabund_pca_grp$tension, color = pore_relabund_pca_grp$treatment))+
  scale_shape_manual(values = c(19,4))+
  facet_wrap(~groups)

adonis(pore_relabund_pca_num ~ pore_relabund_pca$site+pore_relabund_pca$treatment+pore_relabund_pca$site:pore_relabund_pca$treatment, 
       method="bray", permutations=999)

## treatment PCA: fine pores

pore_relabund_pca=
  relabund_temp %>% 
  ungroup %>% 
  dplyr::select(core,tension, site, treatment, Class, relabund) %>% 
  #filter(treatment=="time zero saturation") %>% 
  filter(tension=="50 kPa") %>% 
  spread(Class, relabund) %>% 
  replace(.,is.na(.),0) 

pore_relabund_pca_num = 
  pore_relabund_pca %>% 
  dplyr::select(.,-(1:4))

pore_relabund_pca_grp = 
  pore_relabund_pca %>% 
  dplyr::select(.,(1:4)) %>% 
  dplyr::mutate(row = row_number())

pca = prcomp(pore_relabund_pca_num, scale. = T)
summary(pca)

ggbiplot(pca, obs.scale = 1, var.scale = 1, 
         groups = pore_relabund_pca_grp$site, ellipse = F, circle = F,
         var.axes = TRUE)+
  geom_point(size=2,stroke=2, aes(color = pore_relabund_pca_grp$treatment, shape = pore_relabund_pca_grp$site))+
  geom_text(label = pore_relabund_pca_grp$core)+
  scale_shape_manual(values = c(19,4,7))+
  #facet_wrap(~groups)+
  ggtitle("fine pores")

adonis(pore_relabund_pca_num ~ pore_relabund_pca$site+pore_relabund_pca$treatment+pore_relabund_pca$site:pore_relabund_pca$treatment, 
       method="bray", permutations=999)


## treatment PCA: coarse pores

pore_relabund_pca=
  relabund_temp %>% 
  ungroup %>% 
  dplyr::select(core,tension, site, treatment, Class, relabund) %>% 
  #filter(treatment=="time zero saturation") %>% 
  filter(tension=="1.5 kPa") %>% 
  spread(Class, relabund) %>% 
  replace(.,is.na(.),0) 

pore_relabund_pca_num = 
  pore_relabund_pca %>% 
  dplyr::select(.,-(1:4))

pore_relabund_pca_grp = 
  pore_relabund_pca %>% 
  dplyr::select(.,(1:4)) %>% 
  dplyr::mutate(row = row_number())

pca = prcomp(pore_relabund_pca_num, scale. = T)
summary(pca)

ggbiplot(pca, obs.scale = 1, var.scale = 1, 
         groups = pore_relabund_pca_grp$site, ellipse = F, circle = F,
         var.axes = TRUE)+
  geom_point(size=2,stroke=2, aes(color = pore_relabund_pca_grp$treatment, shape = pore_relabund_pca_grp$site))+
  scale_shape_manual(values = c(19,4,7))+
  geom_text(label = pore_relabund_pca_grp$core)+
  #facet_wrap(~groups)+
  ggtitle("coarse pores")






## b. soils ----
## native SOM pca
soil_relabund_pca=
  soil_relabund_temp %>% 
  ungroup %>% 
  dplyr::select(core, site, treatment, Class, relabund) %>% 
  filter(treatment=="time zero saturation") %>% 
  spread(Class, relabund) %>% 
  replace(.,is.na(.),0) %>% 
  dplyr::select(-1)

soil_relabund_pca_num = 
  soil_relabund_pca %>% 
  dplyr::select(.,-(1:2))

soil_relabund_pca_grp = 
  soil_relabund_pca %>% 
  dplyr::select(.,(1:2)) %>% 
  dplyr::mutate(row = row_number())

pca = prcomp(soil_relabund_pca_num, scale. = T)
summary(pca)

ggbiplot(pca, obs.scale = 1, var.scale = 1, 
         groups = soil_relabund_pca_grp$site, ellipse = TRUE, circle = F,
         var.axes = TRUE)+
  geom_point(size=2, stroke=2, aes(color=groups))+
  ylim(-4,4)+xlim(-4,4)+
  ggtitle("time zero saturation")

bray_distance = vegdist(pore_relabund_pca_num, method="euclidean")
principal_coordinates = pcoa(bray_distance)

pcoa_plot = data.frame(principal_coordinates$vectors[,])
pcoa_plot_merged = merge(pcoa_plot, pore_relabund_pca_grp, by="row.names")

####### Calculate percent variation explained by PC1, PC2

PC1 <- 100*(principal_coordinates$values$Eigenvalues[1]/sum(principal_coordinates$values$Eigenvalues))
PC2 <- 100*(principal_coordinates$values$Eigenvalues[2]/sum(principal_coordinates$values$Eigenvalues))
PC3 <- 100*(principal_coordinates$values$Eigenvalues[3]/sum(principal_coordinates$values$Eigenvalues))

###### Plot PCoA

ggplot(data=pcoa_plot_merged,aes(x=Axis.1,y=Axis.2,color=treatment, shape=site)) + 
  geom_point(size=4)+
  facet_grid(tension~site)+
  stat_ellipse()+
  theme_kp()+
  theme(legend.position = "right")+
  labs(x = paste("PC1 - Variation Explained", round(PC1,2),"%"), y = paste("PC2 - Variation Explained", round(PC2,2),"%"))


## treatment PCA

soil_relabund_pca=
  soil_relabund_temp %>% 
  ungroup %>% 
  dplyr::select(core, site, treatment, Class, relabund) %>% 
  filter(!treatment=="baseline") %>% 
  spread(Class, relabund) %>% 
  replace(.,is.na(.),0) %>% 
  dplyr::select(-1)

soil_relabund_pca_num = 
  soil_relabund_pca %>% 
  dplyr::select(.,-(1:2))

soil_relabund_pca_grp = 
  soil_relabund_pca %>% 
  dplyr::select(.,(1:2)) %>% 
  dplyr::mutate(row = row_number())

pca = prcomp(soil_relabund_pca_num, scale. = T)
summary(pca)

ggbiplot(pca, obs.scale = 1, var.scale = 1, 
         groups = soil_relabund_pca_grp$treatment, ellipse = T, circle = F,
         var.axes = TRUE)+
  geom_point(size=2, stroke=1,aes(shape = soil_relabund_pca_grp$site, color = groups))+
  scale_shape_manual(values = c(1,0,2))

adonis(soil_relabund_pca_num ~ soil_relabund_pca$site+soil_relabund_pca$treatment+soil_relabund_pca$site:soil_relabund_pca$treatment, 
       method="bray", permutations=999)
