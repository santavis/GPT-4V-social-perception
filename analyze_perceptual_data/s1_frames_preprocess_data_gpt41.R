# GPT social perception: Preprocess the GPT4.1 data for frame experiment
#   1. Read data for each batch and add the frame names to the dataframes
#   2. Exclude rows that have nan data in at least one dataset
#   3. Exclude columns that dont have any variation from zero in at least one dataset
#   4. Calculate mean datasets of all possible combinations of the datasets
#   5. Store results for analyses.

# Severi Santavirta 14.05.2024

library(psych)
library(stringr)
library(gtools)

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Load human data just to match the column names

# Read human data
load('/path/data_megaperception_frames/data_frames_human.RData')
data_nonzero_human <- data
features <- colnames(data_nonzero_human)

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Process GPT data

#Collect data from all batches
data_list <- list()
for(batch in seq(from=1,to=5)){
  
  # Load GPT data
  data_gpt <- read.csv(paste("/path/data_megaperception_frames_gpt41/batch",batch,"/batch",batch,"_data.csv",sep = ""),sep = ",")
  images <- data_gpt$imageNames
  images <- str_replace_all(images,".png","")
  rownames(data_gpt) <- images
  data_gpt <- data_gpt[-1]
  
  # Coughing and vomiting are zero in human dataset
  data_gpt <- data_gpt[,-c(42,43)]
  
  # The columns (features) are in the same order in all datasets
  colnames(data_gpt) <- features
  
  # Sort rows into alphabetical order
  data_gpt <- data_gpt[order(rownames(data_gpt)),]
  
  # Store data to the list of batches
  data_list[[paste(batch,sep = "")]] <- data_gpt
}

##------------------------------------------------------------------------------------------------------------------------------------------
# Calculate the mean dataset of all possible combinations of batches

# Function to calculate the mean of a list of matrices
mean_of_matrices <- function(matrices) {
  Reduce("+", matrices) / length(matrices)
}

# Function to get all combinations and their means
calculate_all_means <- function(data_list) {
  results <- list()
  n <- length(data_list)
  
  for (k in 2:n) {  # Starting from pairs
    combs <- combn(n, k, simplify = FALSE)
    for (comb in combs) {
      selected_matrices <- data_list[comb]
      mean_matrix <- mean_of_matrices(selected_matrices)
      results[[paste(comb, collapse = ",")]] <- mean_matrix
    }
  }
  return(results)
}

# Calculate all means
data_mean_list <- calculate_all_means(data_list)

##------------------------------------------------------------------------------------------------------------------------------------------
# Save the data as one list
data <- c(data_list,data_mean_list)
save(data,file = "/path/data_megaperception_frames_gpt41/processed_data_5batches.RData")

