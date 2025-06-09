# GPT social perception: Plot the brain result similarities for each feature as a bar plot (GPT4.1 data)

# Yuhang Wu & Severi Santavirta 9.6.2025

library(readr)
library(ggplot2)
library(reshape2)
library(dplyr)

# Read the data
cor_and_threshold_results <- read.csv("/path/cor_and_threshold_results_gpt41.csv") # After creating this file in Matlab, create a Manual_label column with plottable feature labels

# Plot the raw correlations
sorted_data <- cor_and_threshold_results %>%
  select(Manual_label, Correlation) %>%
  arrange(desc(Correlation))
sorted_data$Manual_label<- factor(sorted_data$Manual_label, levels = sorted_data$Manual_label)

pdf("/path/Fig5_brain_similarity_bars/raw_beta_correlation.pdf",height = 6,width = 20)
ggplot(sorted_data, aes(x = Manual_label, y = Correlation)) +
  geom_bar(stat = "identity",fill = "#0072B2", color = "black") +
  labs(x = NULL, y = NULL) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 270, hjust = 0, vjust = 0.5, size = 12))
dev.off()

# Plot the positive predictive values of the statistically thresholded results
selected_data <- cor_and_threshold_results %>%
  select(Manual_label, TP_norm_FWE, TP_norm_0001)
cor_and_threshold_long <- melt(selected_data, id.vars = "Manual_label", 
                               variable.name = "Type", value.name = "Value")
cor_and_threshold_long$Manual_label <- factor(cor_and_threshold_long$Manual_label, levels = sorted_data$Manual_label)

custom_colors <- c("TP_norm_FWE" = "#e31a1c", "TP_norm_0001" = "white")
pdf("/path/Fig5_brain_similarity_bars/thresholded_ppv.pdf",height = 6,width = 20)
ggplot(cor_and_threshold_long, aes(x = Manual_label, y = Value, fill = Type)) +
  geom_bar(stat = "identity",color = "black",position = position_dodge()) +
  labs(x = NULL, y = NULL) +
  theme_minimal() +
  scale_fill_manual(values = custom_colors) +
  theme(axis.text.x = element_text(angle = 270, hjust = 0,vjust = 0.5,size = 12),
        legend.position = "none",
        )
dev.off()
