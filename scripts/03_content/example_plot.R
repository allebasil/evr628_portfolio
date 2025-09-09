library(EVR628tools)
library(ggplot2)

dat <- EVR628tools::data_lionfish
ggplot(data = dat,
       mapping = aes(x = total_length_mm,
                     y = total_weight_gr))+
  geom_point()+
  labs(x = "Total Length (mm)",
       y = "Weight (g)")
