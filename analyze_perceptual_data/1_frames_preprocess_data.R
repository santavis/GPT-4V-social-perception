# GPT social perception: Preprocess the GPT data for frame perception experiment
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
load('path/data_frames_human.RData')
data_nonzero_human <- data
features <- colnames(data_nonzero_human)

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Process GPT data

#Collect data from all batches
data_list <- list()
missing_images <- c()
for(batch in seq(from=1,to=5)){
  
  # Load GPT data
  data_gpt <- read.csv(paste("path/data_frames/batch",batch,"/batch",batch,"_data.csv",sep = ""),sep = ",")
  frames_gpt <- read.csv(paste("path/data_frames/batch",batch,"/batch",batch,"_frame_order.csv",sep = ""),header = FALSE)
  frame_codes <-  read.csv(paste("path/data_frames/batch",batch,"/batch",batch,"_matchtable.csv",sep = ""))
 
  # Delete extra columns add the end
  data_gpt <- data_gpt[,1:138]
  
  # Coughing and vomiting are zero in human dataset
  data_gpt <- data_gpt[,-c(42,43)]
  
  # The columns (features) are in the same order in all datasets
  colnames(data_gpt) <- features
  
  # Figure out which row corresponds to which image
  indices <- match(frames_gpt$V1,frame_codes$New.Name)
  rownames(data_gpt) <- str_replace_all(frame_codes$Original.Name[indices],".png","")
  
  
  
  # Collect the missing rows
  rows_with_nan <- which(apply(data_gpt, 1, function(x) any(is.na(x))))
  missing_images <- c(missing_images,rownames(data_gpt)[rows_with_nan])
  
  # Delete the rows with NAN values
  if(length(rows_with_nan>0)){
    data_gpt <- data_gpt[-rows_with_nan,]
  }
  
  # Sort rows into alphabetical order
  data_gpt <- data_gpt[order(rownames(data_gpt)),]
  
  # Store data to the list of batches
  data_list[[paste(batch,sep = "")]] <- data_gpt
}

# Find which images failed in at least one dataset
missing_images <- unique(missing_images)

# Analyze only rows that are included in every batch (some videos failed in GPT data)
common_rows <- Reduce(intersect, list(rownames(data_list[[1]]),rownames(data_list[[2]]),rownames(data_list[[3]]),rownames(data_list[[4]]),rownames(data_list[[5]])))
for(batch in seq(from=1,to=5)){
  
  # Select common rows from each batch
  data_gpt <- data_list[[batch]]
  data_list[[batch]] <- data_gpt[common_rows,]
  
  # Identify if there are columns with only zero ratings
  data_gpt_mtx = as.matrix(data_gpt[common_rows,])
  if(batch==1){
    non_zero <- as.integer(colSums(data_gpt_mtx > 0) == 0)
  }else{
    non_zero <- non_zero + as.integer(colSums(data_gpt_mtx > 0) == 0)
  }
  print(sum(as.integer(colSums(data_gpt_mtx > 0) == 0)))
}

# Delete columns that have empty data in one or more datasets (non_zero > 0)
idx <- which(non_zero>0)
if(length(idx>0)){
  for(batch in seq(from=1,to=5)){
    data_gpt <- data_list[[batch]]
    data_list[[batch]] <- data_gpt[,-idx]
  }
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
save(data,file = "path/processed_data_5batches.RData")

