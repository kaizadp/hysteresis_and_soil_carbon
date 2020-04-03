source("0-hysteresis_packages.R")

data_temp = read.csv("data/fticr/Report.csv")

data = 
  data_temp %>% 
  filter(!Class=="None") %>% 
  dplyr::select(-(5:9),
                -Error_ppm,-Candidates, -El_comp,-NeutralMass) %>% 
  tidyr::gather(sample,intensity,6:16) %>% 
  filter(!intensity==0) %>% 
  dplyr::mutate(HC = H/C,
                OC = O/C)


gg_vankrev(data, aes(x=OC,y=HC, color = Class))+
  theme_kp()+
  facet_wrap(~sample)
