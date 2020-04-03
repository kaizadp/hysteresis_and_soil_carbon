# 3Soils
# 3-fticr_initial processing
# Kaizad F. Patel
# October 2019

 ## this script will process the input data and metadata files and
 ## generate clean files that can be used for subsequent analysis.
 ## each dataset will generate longform files of (a) all cores, (b) summarized data for each treatment (i.e. cores combined) 

source("0-hysteresis_packages.R")

install.packages("devtools") 
devtools::install_github("jakelawlor/PNWColors") 
library(PNWColors)
# ------------------------------------------------------- ----

# PART I: FTICR DATA FOR SOIL EXTRACTS ----

## step 1: load the files ----
fticr_report = read.csv("data/fticr/Report.csv") %>% 
  filter(Mass>200 & Mass<900) %>% 
# remove isotopes
  filter(C13==0) %>% 
# remove peaks without C assignment
  filter(C>0)


# this has metadata as well as sample data
# split them

# 1a. create meta file
fticr_meta = 
  fticr_report %>% 
  dplyr::select(-starts_with("FT")) %>% 
# select only necessary columns
  dplyr::select(Mass, C, H, O, N, S, P, El_comp, Class) %>% 
# create columns for indices
  dplyr::mutate(AImod = round((1+C-(0.5*O)-S-(0.5*(N+P+H)))/(C-(0.5*O)-S-N-P),4),
                NOSC =  round(4-(((4*C)+H-(3*N)-(2*O)-(2*S))/C),4),
                HC = round(H/C,2),
                OC = round(O/C,2))

gg_vankrev(fticr_meta, aes(x = OC, y = HC, color = Class))+
  scale_color_viridis_d(option = "inferno")+
  theme_kp()

# 1b. create data file 
fticr_key = read.csv("data/fticr_key.csv")
corekey = read.csv(COREKEY)

corekey_subset = 
  corekey %>% 
  dplyr::select(Core, texture, treatment, perc_sat, Core_assignment) %>% 
  dplyr::mutate(Core = as.factor(Core))



fticr_data = 
  fticr_report %>% 
  dplyr::select(Mass,starts_with("FT")) %>% 
  #tidyr::gather(sample,intensity,FT007:FT006) %>% 
  melt(id = c("Mass"), value.name = "presence", variable.name = "FTICR_ID") %>% 
  dplyr::mutate(presence = if_else(presence>0,1,0)) %>% 
  filter(presence>0) %>% 
  left_join(dplyr::select(fticr_key, Core:FTICR_ID), by = "FTICR_ID") %>% 
# rearrange columns
  dplyr::select(Core, FTICR_ID, Mass, presence) %>% 
  left_join(corekey_subset, by = "Core") %>% 
  dplyr::select(-Mass,-presence,Mass,presence) %>% 
# now we want only peaks that are in all replicates
  group_by(Core_assignment,treatment, texture, perc_sat,Mass) %>% 
  dplyr::summarize(n = n(),
                   presence = mean(presence)) %>% 
  filter(n>2)




# step 2. merge files
fticr = 
  fticr_data %>% 
  left_join(fticr_meta, by = "Mass")

gg_vankrev(fticr, aes(x = OC, y = HC, color = treatment))+
  facet_grid(treatment+texture~perc_sat)+
  theme_kp()+
  ggtitle("peaks seen in 3+ of 5 replicates")


## getting initial summary info
fticr_summ = 
  fticr %>% 
  group_by(Core_assignment,treatment,texture, perc_sat, Mass) %>% 
  dplyr::summarise(n = n())



ggplot(fticr_summ, aes(x = Mass, y = n))+
  geom_point()+
  facet_wrap(~Core_assignment)


# data are split into (a) metadata and (b) sample data
# read_csv reads the zipped files without extracting
fticr_soil_meta = read_csv("data/FTICR_INPUT_SOIL_META.csv.zip")
fticr_soil_data = read_csv("data/FTICR_INPUT_SOIL_DATA.csv.zip")
corekey = read.csv("data/COREKEY.csv")

fticr_soil_meta %>% 
  # remove unnecessary columns
  dplyr::select(-C13,-Error_ppm,-Candidates,-GFE,-bs1_class,-bs2_class) %>% 
  # rename columns
  dplyr::rename(OC = OtoC_ratio,
                HC = HtoC_ratio) %>% 
  filter(!Class=="Unassigned")->
  fticr_soil_meta
## the aromatic index is the corrected index from Dittmar and Koch 2015, https://doi.org/10.1002/rcm.7433

# make a subset for just HCOC and class
fticr_soil_meta %>% 
  dplyr::select(Mass, Class, HC, OC) %>% 
  dplyr::mutate(HC = round(HC, 4),
                OC = round(OC,4))->
  fticr_meta_hcoc

# make a subset for relevant columns


### OUTPUT

      # merge metadata with sample data
      # ¿¿¿ do this later instead? YES
      # fticr_soil = merge(fticr_soil_meta,fticr_soil_data,by = "Mass")

#
## step 2: clean and process ----
fticr_soil_data %>% 
  # melt/gather. transform from wide to long form
  gather(core, intensity, C1:S25) %>% ## core = name of new categ column, intensity = name of values column, C1:C25 are columns that are collapsed
  # remove all samples with zero intensity
  filter(!intensity=="0") %>% 
  # merge with the core key file
  left_join(corekey,by = "core") %>% 
  # merge with hcoc file
  left_join(fticr_meta_hcoc, by = "Mass") %>% 
  group_by(Mass,treatment,site) %>% 
  dplyr::mutate(reps = n())%>% 
  # remove peaks seen in < 3 replicates 
  filter(reps>2) %>% 
  # remove "unassigned" molecules
  filter(!Class=="Unassigned")  ->
  fticr_soil_raw_long
# used to be called:  `fticr_soil_gather2`


        ## fticr_soil_data %>% 
        ##   # melt/gather. transform from wide to long form
        ##   gather(core, intensity, C1:S25) %>% ## core = name of new categ column, intensity = name of values column, C1:C25 are columns that are collapsed
        ##   # remove all samples with zero intensity
        ##   filter(!intensity=="0") %>% 
        ##   # merge with the core key file
        ##   left_join(corekey,by = "core") %>% 
        ##   # merge with hcoc file
        ##   left_join(fticr_meta_hcoc, by = "Mass") %>% 
        ##               # since we are using MolForm instead of Mass, we need to average out Mass values in case peaks are repeated 
        ##               #  group_by(MolForm,Class, core, treatment, site) %>% 
        ##               #  dplyr::summarize(intensity = mean(intensity)) %>% 
        ##   ## now we need to filter only those peaks seen in 3 or more replicates
        ##   # add a column with no. of replicates
        ##   group_by(Mass,treatment,site) %>% 
        ##   dplyr::mutate(reps = n()) %>% 
        ##   # remove peaks seen in < 3 replicates 
        ##   filter(reps>2) %>% 
        ##   # remove "unassigned" molecules
        ##   filter(!Class=="Unassigned")  ->
        ##   fticr_soil_raw_long2
        ## 
        ## fticr_soil_raw_long2 %>% 
        ##   group_by(Mass, core, site, treatment) %>% 
        ##   dplyr::mutate(molform_n = n())->tem        p2


        ## fticr_soil_raw_long %>% 
        ##   group_by(Mass,core,site,treatment) %>% 
        ##   dplyr::summarize(n = n())->temp

## now create a summary of this
fticr_soil_raw_long %>% 
  ungroup %>% 
  group_by(Mass,site,treatment) %>% 
  dplyr::summarize(intensity = mean(intensity)) %>% 
  # merge with hcoc file
  left_join(fticr_meta_hcoc, by = "Mass") ->
  fticr_soil_long

#
### FTICR-SOIL OUTPUT ----
    # write.csv(fticr_soil_gather2,"fticr_soil_longform.csv")

write.csv(fticr_soil_meta, FTICR_SOIL_META, row.names = FALSE)
write.csv(fticr_meta_hcoc, FTICR_SOIL_META_HCOC, row.names = FALSE)
write.csv(fticr_soil_long, FTICR_SOIL_LONG, row.names = FALSE)
write.csv(fticr_soil_raw_long, FTICR_SOIL_RAW_LONG, row.names = FALSE)

#
# ------------------------------------------------------- ----

# PART II: FTICR DATA FOR POREWATER ----
## step 1: load the files ----
# the porewater file contains the Mass/Peak metadata as well as sample intensities data
fticr_porewater = read_csv("data/FTICR_INPUT_SOILPORE.csv.zip")
corekey = read.csv("data/COREKEY.csv")

# this is the link to the google drive file
# https://drive.google.com/file/d/1dMjnCnMUYa5XY2ypVjz2HBQKx7E0YJY1/view?usp=sharing
# use report sn3

# write_csv(fticr_porewater, path = "fticr/fticr_porewater.csv")

#
## step 2: clean and process ----

## 2a: remove unnecessary columns. LOTS of unnecessary columns. fml. 
# This uses a seemingly arbitrary list that's experiment-specific. Kind of sucky

# Create a file with the list of columns to drop. 
# use the sample meta file for this. retain SampleType `sample` and `as`. (I don't know what `as` is.)
# metadata of sample information
pore_sample_meta = read.csv("data/FTICR_INPUT_SOILPORE_meta.csv")

pore_sample_meta %>% 
  filter(!Sample_Type=="sample") %>% 
  filter(!Sample_Type=="as") %>% 
  dplyr::rename(code = `X21T_CCS.2_Day8_1.C11_11Jan18_Leopard_Infuse.qb`) -> 
  # ^^^ rename the f-ing column. WTAF is this column name. Checked -- it's not because a row was moved up. 
  pore_sample_meta

write.csv(pore_sample_meta$code, "data/fticr_columns_to_drop2.txt", row.names = FALSE, quote = FALSE)

# drop unnecessary sample columns 
drops <- readLines("data/fticr_columns_to_drop2.txt")
fticr_porewater[names(fticr_porewater) %in% drops] <- NULL

# clean up sample names because WTF 
# find the sample code (1 number followed by hyphen followed by letter followed by 1-2 numbers)
# example of sample code: 5_C10 == core C10 from CPCRW, -50 kPa porewater

matches <- regexec("[0-9]-[A-Z][0-9]{1,2}", names(fticr_porewater))
matches_n <- unlist(matches)
lengths <- sapply(matches, function(x) attr(x, "match.length"))
# extract the part of the name we want and change
names <- substr(names(fticr_porewater), matches_n, matches_n + lengths - 1)
names(fticr_porewater)[matches_n > 0] <- names[matches_n > 0]

# remove addiitonal unnecessary names that couldn't be automated above
fticr_porewater %>% 
  dplyr::select(-`C13`,-`3use`,-`Error_ppm`)->
  fticr_porewater

### create meta file ----
## sample data split by pore size (50 kPa and 1.5 kPa). 
fticr_porewater %>% 
  dplyr::select(1:11) %>% 
# remove compounds without class. har har. 
  filter(!Class=="None") %>% 
# create new columns  
  dplyr::mutate(AImod = (1+C-(0.5*O)-S-(0.5*(N+P+H)))/(C-(0.5*O)-S-N-P),
                NOSC =  4-(((4*C)+H-(3*N)-(2*O)-(2*S))/C),
                HC = round(H/C,2),
                OC = round(O/C,2))->
  fticr_pore_meta

#### calculate molecular formula
fticr_pore_meta %>% 
  dplyr::select(1:8) %>% 
  dplyr::mutate(mol_C = case_when(C==1 ~ paste("C"),
                                  C>1 ~ paste0("C",C),
                                  C==0 ~ NA_character_),
                mol_H = case_when(H==1 ~ paste("H"),
                                  H>1 ~ paste0("H",H),
                                  H==0 ~ NA_character_),
                mol_O = case_when(O==1 ~ paste("O"),
                                  O>1 ~ paste0("O",O),
                                  O==0 ~ NA_character_),
                mol_N = case_when(N==1 ~ paste("N"),
                                  N>1 ~ paste0("N",N),
                                  N==0 ~ NA_character_),
                mol_S = case_when(S==1 ~ paste("S"),
                                  S>1 ~ paste0("S",S),
                                  S==0 ~ NA_character_),
                mol_P = case_when(P==1 ~ paste("P"),
                                  P>1 ~ paste0("P",P),
                                  P==0 ~ NA_character_),
                mol_Na = case_when(Na==1 ~ paste("Na"),
                                  Na>1 ~ paste0("Na",Na),
                                  Na==0 ~ NA_character_),
                MolForm = paste0(mol_C,mol_H,mol_N,mol_O,mol_S,mol_Na),
                MolForm = str_replace_all(MolForm,"NA","")) %>% 
  dplyr::select(Mass,MolForm)->molform_temp

        ## molform_temp%>% 
        ##   left_join(fticr_pore_meta, by = "Mass")->fticr_pore_meta


# create subset for HCOC and class
fticr_pore_meta %>% 
  dplyr::select(Mass,HC, OC, Class)->
  fticr_pore_meta_hcoc

#
### create data file ----
fticr_porewater %>%
  dplyr::select(Mass, starts_with("5"), starts_with("1")) %>% 
# collapse all core columns into a single column
  melt(id="Mass") %>% 
  dplyr::rename(sample = variable,
                intensity = value) %>% 
# remove all peaks with intensity ==0  
  filter(!intensity==0) %>% 
# using `sample` column, create columns for tension and core
  dplyr::mutate(tension_temp = substr(sample,start=1,stop=1),
                core = substr(sample,start=3,stop=7),
                tension = case_when(
                  tension_temp=="1"~"1.5 kPa",
                  tension_temp=="5"~"50 kPa")) %>% 
# remove unnecessary columns
  dplyr::select(-tension_temp,-sample) %>% 
# merge with the corekey and then remove NA containing rows
  right_join(corekey, by = "core") %>% 
  drop_na->
  temp_pore

# remove peaks seen in < 3 replicates
temp_pore %>% 
  group_by(Mass,tension,site,treatment) %>% 
  dplyr::mutate(reps = n()) %>% 
  filter(reps >2) %>% 
  # merge with hcoc file
  left_join(fticr_pore_meta_hcoc, by = "Mass") %>% 
  drop_na->
  fticr_pore_raw_long

# now create a summary by treatment
fticr_pore_raw_long %>% 
  group_by(Mass,tension,site,treatment) %>% 
  dplyr::summarise(intensity = mean(intensity)) %>% 
  # merge with hcoc file
  left_join(fticr_pore_meta_hcoc, by = "Mass") %>% 
  drop_na->
  fticr_pore_long


### FTICR-PORE OUTPUT ----
write.csv(fticr_pore_meta, FTICR_PORE_META, row.names = FALSE)
write.csv(fticr_pore_long, FTICR_PORE_LONG,row.names = FALSE)
write.csv(fticr_pore_raw_long, FTICR_PORE_RAW_LONG,row.names = FALSE)

#
# ------------------------------------------------------- ----

# PART III: PROCESSING FOR OTHER ANALYSES ----
## a. NOSC  ----
### soil
soil_meta_nosc <- fticr_soil_meta %>% 
  dplyr::select(Mass,NOSC)
soil_nosc <- merge(fticr_soil_long,soil_meta_nosc, by="Mass")

### pore

pore_meta_nosc <- fticr_pore_meta %>% 
  dplyr::select(Mass,NOSC)
pore_nosc <- merge(fticr_pore_long,pore_meta_nosc, by="Mass")

### OUTPUT
write.csv(soil_nosc,FTICR_SOIL_NOSC,row.names = FALSE)
write.csv(pore_nosc,FTICR_PORE_NOSC,row.names = FALSE)


## b. PCA ----
library(devtools)
install_github("vqv/ggbiplot")
library(ggbiplot)
library(vegan)
library("ape")

fticr_pore_raw_long = read.csv(FTICR_PORE_RAW_LONG)# <- "fticr/fticr_pore_longform.csv"

fticr_pore_pca = 
  fticr_pore_raw_long %>% 
#  filter(tension=="1.5 kPa") %>% 
  dplyr::mutate(presence = case_when(intensity>0~1)) %>% 
  dplyr::select(core,Mass,tension,site,treatment,presence) %>%  
  spread(Mass,presence)

fticr_pca_num = 
  fticr_pore_pca %>% 
  dplyr::select(.,-(1:4)) %>% 
  replace(.,is.na(.),0)

fticr_pca_grp = 
  fticr_pore_pca %>% 
  dplyr::select(.,(1:4)) %>% 
  dplyr::mutate(row = row_number())

df_f <- fticr_pca_num[,apply(fticr_pca_num, 2, var, na.rm=TRUE) != 0]

pca = prcomp(df_f, scale. = T)
summary(pca)

ggbiplot(pca, obs.scale = 1, var.scale = 1, 
         groups = fticr_pca_grp$treatment, ellipse = TRUE, circle = TRUE,
         var.axes = FALSE)

## TPC method

bray_distance = vegdist(fticr_pca_num, method="euclidean")
principal_coordinates = pcoa(bray_distance)

pcoa_plot = data.frame(principal_coordinates$vectors[,])
pcoa_plot_merged = merge(pcoa_plot, fticr_pca_grp, by="row.names")

####### Calculate percent variation explained by PC1, PC2

PC1 <- 100*(principal_coordinates$values$Eigenvalues[1]/sum(principal_coordinates$values$Eigenvalues))
PC2 <- 100*(principal_coordinates$values$Eigenvalues[2]/sum(principal_coordinates$values$Eigenvalues))
PC3 <- 100*(principal_coordinates$values$Eigenvalues[3]/sum(principal_coordinates$values$Eigenvalues))

###### Plot PCoA

ggplot(data=pcoa_plot_merged,aes(x=Axis.1,y=Axis.2,color=treatment, shape=site)) + 
  geom_point(size=4)+
  facet_grid(.~tension)+
  #stat_ellipse()+
  theme_kp()+
  labs(x = paste("PC1 - Variation Explained", round(PC1,2),"%"), y = paste("PC2 - Variation Explained", round(PC2,2),"%"))



###### Significance testing

adonis(df_f ~ fticr_pore_pca$site+fticr_pore_pca$treatment+fticr_pore_pca$site:fticr_pore_pca$treatment, method="bray", permutations=100)

## distance matrix
bray_df  =matrixConvert(bray_distance, colname = c("Var1","Var2","dist"))

bray_df2 = 
  bray_df %>% 
  left_join(fticr_pca_grp, by = c("Var1"="row")) %>% 
  left_join(fticr_pca_grp, by = c("Var2"="row")) %>% 
#  dplyr::mutate(NAME = paste(site.x,treatment.x,"-",site.y,treatment.y)) %>% 
# now select only TZSat distances
  dplyr::mutate(TZSAT = case_when(treatment.x=="time zero saturation" | treatment.y=="time zero saturation"~"time zero saturation")) %>% 
  filter(!is.na(TZSAT)) %>% 
  dplyr::mutate(trtx = case_when(!treatment.x=="time zero saturation" ~treatment.x),
                trty = case_when(!treatment.y=="time zero saturation" ~treatment.y),
                TRT = paste(trtx,trty),
                TRT = str_replace_all(TRT,"NA ",""),
                TRT = str_replace_all(TRT," NA",""),
                TRT = str_replace_all(TRT,"NA",""))

    

ggplot(bray_df2, aes(x = TRT, y = dist, color = TRT))+
  geom_boxplot(position = position_dodge(width = 0.7), fill = "white", lwd = 1,fatten = 1, width=0.5)+ # fatten changes thickness of median line, lwd changes thickness of all lines
  geom_point(position = position_dodge(width = 0.7), alpha=0.1, shape=1, size=2)  


bray_summary = melt(as.matrix(bray_distance))

# soil extracts
fticr_soil_long = read.csv(FTICR_SOIL_RAW_LONG) #<- "fticr/fticr_soil_longform.csv"

fticr_soil_pca = 
  fticr_soil_long %>% 
  dplyr::mutate(presence = case_when(intensity>0~1)) %>% 
  dplyr::select(core,Mass,site,treatment,presence) %>%  
  spread(Mass,presence)

fticr_soil_pca_num = 
  fticr_soil_pca %>% 
  dplyr::select(.,-(1:3)) %>% 
  replace(.,is.na(.),0)

fticr_soil_pca_grp = 
  fticr_soil_pca %>% 
  dplyr::select(.,(1:3)) %>% 
  dplyr::mutate(row = row_number())

df_f <- fticr_soil_pca_num[,apply(fticr_soil_pca_num, 2, var, na.rm=TRUE) != 0]

pca = prcomp(df_f, scale. = T)
summary(pca)

ggbiplot(pca, obs.scale = 1, var.scale = 1, 
         groups = fticr_soil_pca_grp$treatment, ellipse = TRUE, circle = TRUE,
         var.axes = FALSE)
ggbiplot(pca, obs.scale = 1, var.scale = 1, 
         groups = fticr_soil_pca_grp$site, ellipse = TRUE, circle = TRUE,
         var.axes = FALSE)


bray_distance = vegdist(fticr_soil_pca_num, method="euclidean")
principal_coordinates = pcoa(bray_distance)

pcoa_plot = data.frame(principal_coordinates$vectors[,])
pcoa_plot_merged = merge(pcoa_plot, fticr_soil_pca_grp, by="row.names")

####### Calculate percent variation explained by PC1, PC2

PC1 <- 100*(principal_coordinates$values$Eigenvalues[1]/sum(principal_coordinates$values$Eigenvalues))
PC2 <- 100*(principal_coordinates$values$Eigenvalues[2]/sum(principal_coordinates$values$Eigenvalues))
PC3 <- 100*(principal_coordinates$values$Eigenvalues[3]/sum(principal_coordinates$values$Eigenvalues))

###### Plot PCoA

ggplot(data=pcoa_plot_merged,aes(x=Axis.1,y=Axis.2,color=treatment, shape=site)) + 
  geom_point(size=4)+
  #facet_grid(.~site)+
  #stat_ellipse()+
  theme_kp()+
  theme(legend.position = "right")+
  labs(x = paste("PC1 - Variation Explained", round(PC1,2),"%"), y = paste("PC2 - Variation Explained", round(PC2,2),"%"))

#

### unique to each site ---- pores ----
unique_pore_temp = 
  fticr_pore_raw_long %>% 
#  filter(reps==5) %>% 
  group_by(Mass, tension, site,  treatment) %>% 
  dplyr::summarize(presence=1) %>% 
  filter(treatment=="time zero saturation") %>% 
  group_by(Mass,tension) %>% 
  dplyr::mutate(reps=sum(presence)) %>% 
  left_join(dplyr::select(fticr_pore_meta, Mass, HC, OC), by = "Mass")


unique_pore = 
  unique_pore_temp %>% 
  filter(reps==1) %>% 
  left_join(dplyr::select(fticr_pore_meta, Mass, HC, OC), by = "Mass")

common_pore = 
  unique_pore_temp %>% 
  filter(reps>1) %>% 
  left_join(dplyr::select(fticr_pore_meta, Mass, HC, OC), by = "Mass")


gg_vankrev(unique_pore, aes(x = OC, y = HC, color = site))+facet_wrap(~tension)

gg_vankrev(unique_pore_temp, aes(x = OC, y = HC, color = site))+
  scale_color_manual(values = c("blue","yellow","red"))+
  facet_wrap(tension~reps)

gg_vankrev(molform[molform$treatment=="time zero saturation",], aes(x = OC, y = HC, color = site))+
  scale_color_manual(values = c("blue","yellow","red"))+
  facet_wrap(treatment+tension~reps)

molform = 
  fticr_pore_raw_long %>% 
  left_join(molform_temp, by = "Mass") %>% 
  group_by(MolForm, core, site, treatment, tension) %>% 
  dplyr::summarise() %>% 
  group_by(MolForm, site, treatment, tension) %>% 
  dplyr::summarise(reps=n()) %>% 
  left_join(dplyr::select(molform_temp, MolForm, HC, OC), by = "MolForm")

molform_temp = 
  molform_temp %>% 
  left_join(dplyr::select(fticr_pore_meta, Mass, HC, OC), by = "Mass")


unique_pore_temp = 
  molform %>% 
  #  filter(reps==5) %>% 
  group_by(MolForm, tension, site,  treatment) %>% 
  dplyr::summarize(presence=1) %>% 
  filter(treatment=="time zero saturation") %>% 
  group_by(MolForm,tension) %>% 
  dplyr::mutate(reps=sum(presence)) %>% 
  left_join(dplyr::select(molform_temp, MolForm, HC, OC), by = "MolForm")


## unique to each site by treatment ----

unique_pore_temp = 
  fticr_pore_raw_long %>% 
  #  filter(reps==5) %>% 
  group_by(Mass, tension, site,  treatment) %>% 
  dplyr::summarize(presence=1) %>% 
  #filter(treatment=="time zero saturation") %>% 
  group_by(Mass,tension, treatment) %>% 
  dplyr::mutate(reps=sum(presence)) %>% 
  left_join(dplyr::select(fticr_pore_meta, Mass, HC, OC), by = "Mass")

# trying to track molecules. only peaks that were initially unique to each site are plotted across the treatments
# not sure if this even makes sense. remove?
temp = 
  unique_pore_temp %>% 
  dplyr::mutate(remove=case_when((treatment=="time zero saturation" & reps==1)~"keep")) %>% 
  ungroup %>% 
  dplyr::select(Mass, tension, site, remove) %>% 
  na.omit()

unique_pore_temp = 
  unique_pore_temp %>% 
  left_join(temp,  by = c("Mass","tension","site"))
  

gg_vankrev(unique_pore_temp, aes(x = OC, y = HC, color = site))+
  scale_color_manual(values = c("blue","yellow","red"))+
  facet_grid(treatment~reps)
