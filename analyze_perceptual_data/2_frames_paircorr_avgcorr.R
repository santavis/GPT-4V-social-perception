# GPT social perception: Calculate how similarly GPT evaluated frame experiment data compared to real human participants

# Severi Santavirta 14.5.2024

library(psych)
library(stringr)
library(gtools)

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Load human data just to match the column names

# Read human data
load('path/data_frames_human.RData')
data_nonzero_human <- data

# Load the image order for humans
frames_human <- read.csv('path/frame_order.csv')

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Load preprocessed GPT data
load("path/processed_data_5batches.RData")

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Calculate pairwise correlations and average correlations separately for each dataset and within each dataset the correlations are calculated separately for each videoset (6 set) and feature (136 features)

features <- colnames(data[[1]])
features <- str_replace_all(features," ","_")
paircorr_human_mean <- matrix(NA,nrow = length(features),length(data))
paircorr_gpt_mean <- matrix(NA,nrow = length(features),length(data))
avgcorr_human_mean <- matrix(NA,nrow = length(features),length(data))
avgcorr_gpt_mean <- matrix(NA,nrow = length(features),length(data))

for(dataset in seq(from = 1,to=length(data))){
  print(paste("Calculating correlations, dataset ",dataset,sep = ""))
  
  paircorr_human<- matrix(0,ncol = 6,nrow = length(features))
  paircorr_gpt <- matrix(0,ncol = 6,nrow = length(features))
  avgcorr_human <- matrix(0,ncol = 6,nrow = length(features))
  avgcorr_gpt <- matrix(0,ncol = 6,nrow = length(features))
  for(set in seq(from=1,to=6)){
    
    # Images of this videoset
    images_set <- frames_human$V1[frames_human$videoset==set]
    images_set <- str_replace_all(images_set,".png","")
    
    # Which images we have in the GPT datasets
    data_dataset <- data[[dataset]]
    images <- intersect(images_set,rownames(data_dataset))
    
    # Select the data for these images
    data_gpt_set <- data_dataset[images,]
    
    # Calculate the pairwise correlations and average correlations for this video set
    for(feat in seq(from=1,to=ncol(data_gpt_set))){
      
      # Load human data
      data_human <- read.csv(paste("path/data_frames_human_individual/",features[feat],"_",set,".csv",sep=""))
      rownames(data_human) <- images_set
      
      # Match data with the GPT dataset
      data_human_set <- data_human[images,]
      
      # Pairwise correlations between individual ratings
      data_pairs <- cbind(data_human_set,data_gpt_set[,feat])
      
      # Calculate pairwise correlations
      gpt_idx <- c()
      paircorr<- c()
      n <- 0
      for(sub1 in seq(from=1,to=(ncol(data_pairs)-1))){
        
        # Select subject one
        data_sub1 <- data_pairs[,sub1]
       
        for(sub2 in seq(from=(sub1+1),to=ncol(data_pairs))){
          
          # Select subject 2
          n <- n+1
          data_sub2 <- data_pairs[,sub2]
          
          # Calculate pairwise correlation
          paircorr[n] <- cor(data_sub1,data_sub2)

          # Identify pairs involving gpt
          if(sub2==ncol(data_pairs)){
            gpt_idx[n] <- 1
          }else{
            gpt_idx[n] <- 0
          }
        }
      }
      
      # Calculate mean of pairwise correlations in all pairs where are only humans and between pairs where gpt is involved
      paircorr_human[feat,set] <- mean(paircorr[gpt_idx==0],na.rm = T)
      paircorr_gpt[feat,set] <- mean(paircorr[gpt_idx==1],na.rm = T)
      
      # Correlations between individual raters compared to the average of others humans (GPT ratings are not included in the average calculations)
      avgcorr_human_feat <- c()
      n <- 0
      for(sub in seq(from=1,to=(ncol(data_pairs)))){
        
        # Calculate the mean of others (not GPT)
        if(sub<ncol(data_pairs)){
          data_for_mean <- data_pairs[,-c(sub,ncol(data_pairs))]
        }else{
          data_for_mean <- data_pairs[,-sub]
        }
        avg <- rowMeans(data_for_mean)
        
        # Calculate the correlation of an individual with the mean of others
        if(sub==ncol(data_pairs)){ # GPT
          avgcorr_gpt[feat,set] <- cor(avg,data_pairs[,sub])
        }else{ # Human
          n <- n+1
          avgcorr_human_feat[n] <- cor(avg,data_pairs[,sub])
        }
      }
      avgcorr_human[feat,set] <- mean(avgcorr_human_feat,na.rm = T)
    }
  }
  
  # Means over videosets
  paircorr_human_mean[,dataset] <- rowMeans(paircorr_human,na.rm = T)
  paircorr_gpt_mean[,dataset] <- rowMeans(paircorr_gpt,na.rm = T)
  avgcorr_human_mean[,dataset] <- rowMeans(avgcorr_human,na.rm = T)
  avgcorr_gpt_mean[,dataset] <- rowMeans(avgcorr_gpt,na.rm = T)
}

##----------------------------------------------------------------------------------------------------------------------------------------------------------------
# Save results

# Make data frames
paircorr <- as.data.frame(paircorr_gpt_mean)
rownames(paircorr) <- features
colnames(paircorr) <- names(data)
avgcorr <- as.data.frame(avgcorr_gpt_mean)
rownames(avgcorr) <- features
colnames(avgcorr) <- names(data)

# Human data is the same for each dataset, no need to save all
paircorr$human <- paircorr_human_mean[,1]
avgcorr$human <- avgcorr_human_mean[,1]

# Save
write.csv(paircorr,"path/paircorr_table.csv",row.names = T)
write.csv(avgcorr,"path/avgcorr_table.csv",row.names = T)