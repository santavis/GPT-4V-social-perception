# GPT social perception: Plot the brain result similarities for each feature as a bar plot (GPT4 data)

# Yuhang Wu & Severi Santavirta 9.6.2025

library(readr)
library(ggplot2)
library(reshape2)
library(dplyr)

# Read the data
cor_and_threshold_results <- read.csv("/path/Fig5_brain_similarity_bars/cor_and_threshold_results.csv")
names_corrected <- readxl::read_xlsx("/path/Fig5_brain_similarity_bars/cor_and_threshold_results.xlsx")
cor_and_threshold_results$Feature_names <- names_corrected$Feature_names

# Plot the raw correlations
sorted_data <- cor_and_threshold_results %>%
  select(Feature_names, Correlation) %>%
  arrange(desc(Correlation))
sorted_data$Feature_names <- factor(sorted_data$Feature_names, levels = sorted_data$Feature_names)

pdf("/path/Fig5_brain_similarity_bars/raw_beta_correlation.pdf",height = 6,width = 20)
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

pdf("/path/Fig5_brain_similarity_bars/thresholded_ppv.pdf",height = 6,width = 20)
ggplot(cor_and_threshold_long, aes(x = Feature_names, y = Value, fill = Type)) +
  geom_bar(stat = "identity",color = "black",position = position_dodge()) +
  labs(x = "Feature", y = "Value") +
  theme_minimal() +
  scale_fill_manual(values = custom_colors) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1,vjust = 0.4,size = 14),
        legend.position = "none")
dev.off()
