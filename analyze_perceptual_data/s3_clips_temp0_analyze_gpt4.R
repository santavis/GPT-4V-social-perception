# Compare the social perceptual evaluations between GPT4 Vision and humans in the video experiment temp0 pilot data

# Severi Santavirta 15.5.2024

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Process human data

# Read human data
load('/path/data_megaperception_clips/data_clips_human.RData')
data_nonzero_human <- data

# Load video order (data are saved in spreadsheet order and from the PicDips1 to PicDisp6)
videos_human <- read.csv('/path/data_megaperception_clips/megaperception_clip_order.csv',sep = ";")
videos_human <- str_replace_all(videos_human$V1,".mp4","")
rownames(data_nonzero_human) <- videos_human

# Sort alphabetically
data_nonzero_human <- data_nonzero_human[order(rownames(data_nonzero_human)),]

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Load preprocessed GPT data

load("/path/data_megaperception_clips_temp0/processed_data_1batches.RData")
features <- colnames(data[[1]])

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Match human data with GPT

# Analyze only rows that we have in each data (some videos failed in GPT data)
common_rows <- Reduce(intersect, list(rownames(data[[1]]),rownames(data_nonzero_human)))
data_nonzero_human <- data_nonzero_human[common_rows,]
colnames(data_nonzero_human) <- features

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Correlation between the raw ratings between human average and GPT datasets

correlations_raw <- matrix(NA,nrow = ncol(data_nonzero_human),ncol = length(data))
for(dataset in seq(from=1,to=length(data))){
  
  # Select the dataset
  data_gpt <- data[[dataset]]
  
  # Calculate correlations for each feature
  for(feat in seq(from=1,to=ncol(data_gpt))){
    correlations_raw[feat,dataset] <- cor(data_gpt[,feat],data_nonzero_human[,feat])
  }
}
