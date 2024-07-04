
# date: 01-07-24
# author: VB
# purpose: Present latest creation data against govt & CCC targets

### working dirs ---------------------------------------------------------------

wd <- "C:/Users/vbu/OneDrive - the Woodland Trust/Projects/CO&E - SoWT2/Project-SoWT2" # WT laptop path
dirData <- paste0(wd,"/data-raw/")
dirScratch <- paste0(wd,"/data-scratch/")
dirOut <- paste0(wd,"data-out")

### libraries ------------------------------------------------------------------

library(tidyverse)
library(ggplot2)
#library(stringr)
library(cowplot)
library(viridis)
library(ggpubr)

### read in data ---------------------------------------------------------------

# downloaded from https://www.forestresearch.gov.uk/tools-and-resources/statistics/data-downloads/
# on 01-07-2024
# converted selected spreadsheets to csv format

dfCreation <- read.csv(paste0(dirData,"forestry_stats_2024_creation_collated.csv"))

head(dfCreation)
summary(dfCreation)

# [low] means less than 0.005 tha.
dfCreation$Private_conifers_tha[which(dfCreation$Private_conifers_tha == "[low]")] <- 0.005
dfCreation$Private_broadleaves_tha[which(dfCreation$Private_broadleaves_tha == "[low]")] <- 0.005
dfCreation$Public_conifers_tha[which(dfCreation$Public_conifers_tha == "[low]")] <- 0.005
dfCreation$Public_broadleaves_tha[which(dfCreation$Public_broadleaves_tha == "[low]")] <- 0.005

# convert some vars to numeric
dfCreation$Private_conifers_tha <- as.numeric(str_replace_all(dfCreation$Private_conifers_tha,",",""))
dfCreation$Private_broadleaves_tha <- as.numeric(str_replace_all(dfCreation$Private_broadleaves_tha,",",""))
dfCreation$Public_conifers_tha <- as.numeric(str_replace_all(dfCreation$Public_conifers_tha,",",""))
dfCreation$Public_broadleaves_tha <- as.numeric(str_replace_all(dfCreation$Public_broadleaves_tha,",",""))

summary(dfCreation)

### wrangle --------------------------------------------------------------------

dfCreation_long <- dfCreation %>% 
  mutate(Total_tha = NULL) %>% 
  gather(., sector, thousand.ha, Private_conifers_tha:Public_broadleaves_tha, factor_key = T) %>% 
  mutate(type = str_split(sector, "_", simplify = TRUE)[ , 2],
         sector = str_split(sector, "_", simplify = TRUE)[ , 1])

### plot -----------------------------------------------------------------------

# (p1 <- dfCreation_long %>% 
#    #filter(forest.stat == "creation.t.ha") %>% 
#    ggplot()+
#    geom_area(aes(Year,thousand.ha, fill = sector), na.rm = T)+
#    scale_fill_manual(values = c("#AFFACE","#497A5E"))+
#    facet_grid(Country~type)+
#    theme_light()+
#    ylab("Woodland creation (thousand ha)")+xlab("Year")+
#    labs(fill="Woodland type")+
#    theme(title = element_text(size = 22, face = "bold", family = "Calibri"),
#          axis.title.x = element_blank(),
#          axis.title.y = element_text(size = 20, face = "bold", margin = margin(r = 15)),
#          axis.text.y = element_text(size = 18),
#          axis.text.x = element_text(size = 18),
#          axis.ticks.x = element_blank(),
#          legend.title = element_text(size = 20, face = "bold"),
#          legend.text = element_text(size = 18),
#          strip.text = element_text(face="bold", size = 12)))


# reproduce fig from SoWT1
# stacked bar plot
# Average area of woodland planting achieved (2016-2020) (green), and deficit relative to CCC minimum recommendations (dark blue), by country 
# Percentage labels show the average proportion of the recommendations achieved. 
# Whiskers indicate standard annual deviation in woodland planting.

# Need to:
# sum creation achieved from 2016 - 2024
dfCreation_summary <- dfCreation_long %>% 
  group_by(Year, Country) %>% 
  summarise(thousand.ha = sum(thousand.ha)) %>% 
  mutate(ha_created = thousand.ha*1000) %>% 
  filter(Year >=2016 & Year <= 2024) %>% 
  group_by(Country) %>% 
  summarise(Achieved = mean(ha_created),
            SD = sd(ha_created)) %>% 
# obtain CCC minimum recommendations per UK country
  mutate(CCC = ifelse(Country == "England", 10000,
                      ifelse(Country == "Northern Ireland", 2000,
                             ifelse(Country == "Scotland", 18000,
                                    ifelse(Country == "Wales", 5000, 
                                           ifelse(Country == "UK", 33000, NA))))),
         Deficit = CCC - Achieved,
# work out the deficit and what's been created as a percentage of the recommendation
        Percentage = round(Achieved/CCC*100, digits = 0))



(p1 <- dfCreation_summary %>% 
  gather(., Progress, Created_ha, c("Achieved", "Deficit"), factor_key = T) %>% 
  ggplot()+
  geom_col(aes(x = Country, y = Created_ha, fill = Progress), position = position_stack(reverse = TRUE))+
  guides(fill = guide_legend(reverse = TRUE))+
  #geom_errorbar(aes(x=Country, ymin = c(actual.av - actual.sd, rep(NA, length(actual.av))), ymax = c(actual.av + actual.sd, rep(NA, length(actual.av)))), width=.2) +
  scale_fill_viridis(discrete = T, option = "D") +
  scale_y_continuous(name = "Planting (ha/year)", limits = c(0, 38000), labels = scales::comma)+
  scale_x_discrete(name = "Region")+
  geom_text(aes(label = paste0(Percentage,"%"), y=CCC, x=Country, vjust= -0.5))+
  ggtitle("Average annual planting 2016-2024\ncompared to CCC reccomendations") +
  #theme_cowplot(12) +
  theme_pubr()+
  theme(text = element_text(family = "sans", color = "#22211d"),
        plot.title = element_blank(),
        plot.subtitle = element_text(size = 12),
        legend.title = element_blank(),
        legend.text =  element_text(size = 12),
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 10),
        axis.title.y =  element_text(size = 12, vjust = 2.2 ),
        axis.title.x =  element_blank(),
        legend.position = "right"))