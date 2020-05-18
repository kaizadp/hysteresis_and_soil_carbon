source("0-hysteresis_packages.R")


# PART I. SETTING UP THE PARAMETERS ----
## 1. set up bins ----

## choose which set of BINS SET to use
cat("ACTION: choose correct value of BINSET
      a.> Clemente2012
      b.> Lynch2019
  type this into the code
  e.g.: BINSET = [quot]Clemente2012[quot]")

BINSET = "Clemente2012"

bins = read_csv("nmr_bins.csv")
bins2 = 
  bins %>% 
  # here we select only the BINSET we chose above
  dplyr::select(group,startstop,BINSET) %>% 
  na.omit %>% 
  spread(startstop,BINSET) %>% 
  arrange(start) %>% 
  dplyr::mutate(number = row_number())


#
## 2. bins for water and DMSO solvent ----
WATER_start = 3
WATER_stop = 4

DMSO_start = 2.20
DMSO_stop = 2.75

## bins for relative abundance





## ALIPHATIC1_START = bins2$shift[bins2=="aliphatic1_start"]
## ALIPHATIC1_STOP = bins2$shift[bins2=="aliphatic1_stop"]
## ALIPHATIC2_START = bins2$shift[bins2=="aliphatic2_start"]
## ALIPHATIC2_STOP = bins2$shift[bins2=="aliphatic2_stop"]
## OALKYL_START = bins2$shift[bins2=="oalkyl_start"]
## OALKYL_STOP = bins2$shift[bins2=="oalkyl_stop"]
## ALPHAH_START = bins2$shift[bins2=="alphah_start"]
## ALPHAH_STOP = bins2$shift[bins2=="alphah_stop"]
## AROMATIC_START = bins2$shift[bins2=="aromatic_start"]
## AROMATIC_STOP = bins2$shift[bins2=="aromatic_stop"]
## AMIDE_START = bins2$shift[bins2=="amide_start"]
## AMIDE_STOP = bins2$shift[bins2=="amide_stop"]


## 3. spectra plot parameters ----
gg_nmr =
  ggplot()+
  # stagger bracketing lines for odd vs. even rows  
  geom_rect(data=bins2 %>% dplyr::filter(row_number() %% 2 == 0), 
            aes(xmin=start, xmax=stop, ymin=3, ymax=3), color = "black")+
  geom_rect(data=bins2 %>% dplyr::filter(row_number() %% 2 == 1), 
            aes(xmin=start, xmax=stop, ymin=2.8, ymax=2.8), color = "black")+
  # stagger numbering like the lines
  geom_text(data=bins2 %>% dplyr::filter(row_number() %% 2 == 0), 
            aes(x = (start+stop)/2, y = 3.1, label = number))+
  geom_text(data=bins2 %>% dplyr::filter(row_number() %% 2 == 1), 
            aes(x = (start+stop)/2, y = 2.9, label = number))+
  scale_x_reverse(limits = c(10,0))+
  xlab("shift, ppm")+
  ylab("intensity")+
  
  theme_classic() %+replace%
  theme(legend.position = "right",
        legend.key=element_blank(),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.key.size = unit(1.5, 'lines'),
        panel.border = element_rect(color="black",size=1.5, fill = NA),
        
        plot.title = element_text(hjust = 0.05, size = 14),
        axis.text = element_text(size = 14, color = "black"),
        axis.title = element_text(size = 14, face = "bold", color = "black"),
        
        # formatting for facets
        panel.background = element_blank(),
        strip.background = element_rect(colour="white", fill="white"), #facet formatting
        panel.spacing.x = unit(1.5, "lines"), #facet spacing for x axis
        panel.spacing.y = unit(1.5, "lines"), #facet spacing for x axis
        strip.text.x = element_text(size=12, face="bold"), #facet labels
        strip.text.y = element_text(size=12, face="bold", angle = 270) #facet labels
  )
#

