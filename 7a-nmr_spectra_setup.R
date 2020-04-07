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
  spread(startstop,BINSET)


#
## 2. bins for water and DMSO solvent ----
WATER_start = 3
WATER_stop = 4

DMSO_start = 2.25
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
  geom_rect(data=bins2, aes(xmin=start, xmax=stop, ymin=-Inf, ymax=+Inf, fill=group), color="grey70",alpha=0.1)+
  scale_x_reverse(limits = c(10,0))+
  xlab("shift, ppm")+
  ylab("intensity")+
  
  # labels:
  annotate("text", label = "aliphatic", x = 1.4, y = -0.1)+
  annotate("text", label = "O-alkyl", x = 3.5, y = -0.1)+
  annotate("text", label = "alpha-H", x = 4.45, y = -0.1)+
  annotate("text", label = "aromatic", x = 7, y = -0.1)+
  annotate("text", label = "amide", x = 8.1, y = -0.1)+
  annotate("text", label = "\n\nWATER", x = 3.5, y = Inf)+
  annotate("text", label = "\n\nDMSO", x = 2.48, y = Inf)+
  geom_vline(xintercept = WATER_start, linetype="longdash")+
  geom_vline(xintercept = WATER_stop, linetype="longdash")+
  geom_vline(xintercept = DMSO_start, linetype="dashed")+
  geom_vline(xintercept = DMSO_stop, linetype="dashed")+
  
  theme_bw() %+replace%
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

