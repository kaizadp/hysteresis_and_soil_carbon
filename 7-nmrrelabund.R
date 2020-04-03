
source("6-nmrprocessing_peaks.R")

spectra3 = 
  subset(merge(spectra2, bins2), start <= ppm & ppm <= stop) %>% 
  #dplyr::select(source,ppm, Area, group) %>% 
  #filter(!(ppm>DMSO_start&ppm<DMSO_stop)) %>% 
  group_by(Core, group, treatment, perc_sat, soil_type) %>% 
  dplyr::summarize(area = sum(Area)) %>% 
  group_by(Core) %>% 
  dplyr::mutate(total = sum(area),
                relabund = round((area/total)*100,2))%>% 
  mutate(pos = cumsum(relabund)- relabund/2)

ggplot(data=spectra3[spectra3$soil_type=="Soil"&!spectra3$treatment=="FM",], aes(x="", y=relabund, fill=group)) +
  geom_bar(stat="identity", alpha=0.7) +
  #geom_text(aes(x= "", y=pos, label = relabund), size=4) +  # note y = pos
  #facet_wrap(facets = .~source, labeller = label_value) +
  facet_wrap(perc_sat+treatment~Core)+
  coord_polar(theta = "y")+
  theme_bw()


ggplot(data=spectra3[spectra3$soil_type=="Soil_sand"&!spectra3$treatment=="FM",], aes(x="", y=relabund, fill=group)) +
  geom_bar(stat="identity", alpha=0.7) +
  #geom_text(aes(x= "", y=pos, label = relabund), size=4) +  # note y = pos
  #facet_wrap(facets = .~source, labeller = label_value) +
  facet_wrap(perc_sat+treatment~Core)+
  coord_polar(theta = "y")+
  theme_bw()

### COMPARING RELABUND by peaks only vs. integration

# 1. peaks only

SPECTRA_134 = read.table("data/134_PEAKSPECTRUM.csv", col.names = c("ppm","intensity"))
PEAKS_134 = read.csv("data/134_PEAKSONLY.csv")

spectra = 
  subset(merge(SPECTRA_134, bins2), start <= ppm & ppm <= stop) %>% 
  dplyr::select(ppm, intensity, group) %>% 
  #filter(!(ppm>DMSO_start&ppm<DMSO_stop)) %>% 
  group_by(group) %>% 
  dplyr::summarize(intensity = sum(intensity)) %>% 
 # group_by(source) %>% 
  dplyr::mutate(total = sum(intensity),
                relabund = round((intensity/total)*100,2))%>% 
  mutate(pos = cumsum(relabund)- relabund/2)

peaks = 
  subset(merge(PEAKS_134, bins2), start <= ppm & ppm <= stop) %>% 
  dplyr::select(ppm, Area, group) %>% 
  #filter(!(ppm>DMSO_start&ppm<DMSO_stop)) %>% 
  group_by(group) %>% 
  dplyr::summarize(intensity = sum(Area)) %>% 
  # group_by(source) %>% 
  dplyr::mutate(total = sum(intensity),
                relabund = round((intensity/total)*100,2))%>% 
  mutate(pos = cumsum(relabund)- relabund/2)


gg_nmr+
  geom_point(data=SPECTRA_134, aes(x = ppm, y = intensity))+
  ylim(-1000,6000)+
  
  # if you need to add labels:
  annotate("text", label = "aliphatic", x = 1.4, y = -700)+
  annotate("text", label = "O-alkyl", x = 3.5, y = -700)+
  annotate("text", label = "alpha-H", x = 4.45, y = -700)+
  annotate("text", label = "aromatic", x = 7, y = -700)+
  annotate("text", label = "amide", x = 8.1, y = -700)+
  annotate("text", label = "\n\nWATER", x = 3.5, y = Inf)+
  annotate("text", label = "\n\nDMSO", x = 2.48, y = Inf)+
  geom_vline(xintercept = WATER_start, linetype="longdash")+
  geom_vline(xintercept = WATER_stop, linetype="longdash")+
  geom_vline(xintercept = DMSO_start, linetype="dashed")+
  geom_vline(xintercept = DMSO_stop, linetype="dashed")
  
  facet_wrap(~source, scales = "free_y")+theme(legend.position = "none")
