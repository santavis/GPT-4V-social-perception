# GPT social pereption, Figure 4: Plot the fMRI comparison results

# Yuhang Wu & Severi Santavirta 8.8.2024

library(readr)
library(ggplot2)
library(reshape2)
library(dplyr)

# Read the data
cor_and_threshold_results <- read.csv("path/cor_and_threshold_results.csv")

# Plot the raw correlations
sorted_data <- cor_and_threshold_results %>%
  select(Features, Correlation) %>%
  arrange(desc(Correlation))
sorted_data$Feature_names <- factor(sorted_data$Features, levels = sorted_data$Features)

pdf("path/raw_beta_correlation.pdf",height = 6,width = 20)
ggplot(sorted_data, aes(x = Feature_names, y = Correlation)) +
  geom_bar(stat = "identity",fill = "#0072B2", color = "black") +
  labs(x = "Feature", y = "Correlation") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1,size = 14))
dev.off()

# Plot the positive predictive values of the statistically thresholded results
selected_data <- cor_and_threshold_results %>%
  select(Feature_names, TP_norm_FWE, TP_norm_0001)
cor_and_threshold_long <- melt(selected_data, id.vars = "Feature_names", 
                               variable.name = "Type", value.name = "Value")
cor_and_threshold_long$Feature_names <- factor(cor_and_threshold_long$Feature_names, levels = sorted_data$Feature_names)
custom_colors <- c("TP_norm_FWE" = "#e31a1c", "TP_norm_0001" = "white")
pdf("path/thresholded_ppv.pdf",height = 6,width = 20)
ggplot(cor_and_threshold_long, aes(x = Feature_names, y = Value, fill = Type)) +
  geom_bar(stat = "identity",color = "black",position = position_dodge()) +
  labs(x = "Feature", y = "Value") +
  theme_minimal() +
  scale_fill_manual(values = custom_colors) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1,vjust = 0.4,size = 14),
        legend.position = "none")
dev.off()
