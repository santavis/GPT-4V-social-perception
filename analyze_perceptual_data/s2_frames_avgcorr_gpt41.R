# GPT social perception: Calculate how similarly GPT4.1 evaluated frame experiment data compared to real human participants.
#
# Process:
#       1. We have approximately 10 human raters select all possible combinations of K raters, K = {1,2,3,4,5}
#       2. Calculate the average correlation between the left_out_group and other humans
#       3. Calculate the average between GPT ratings and human average  (calculated over all raters)
#       4. Store results separately for each K for later comparison.

# Severi Santavirta 27.5.2025

library(psych)
library(stringr)
library(gtools)

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Load human data just to match the column names

# Read human data
load('/path/data_megaperception_frames_gpt41/data_frames_human.RData')
data_nonzero_human <- data

# Load the image order for humans
frames_human <- read.csv('/path/data_megaperception_frames_gpt41/megaperception_movieframes_image_order.csv')

# How many human to left out
khuman = c(1,2,3,4,5)

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Load preprocessed GPT data
load("/path/data_megaperception_frames_gpt41/processed_data_5batches.RData")

# Choose only the last GPT dataset (average of all collection rounds)
data_gpt <- data[[length(data)]]

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Calculate correlations between GPT and human average as well as correlations between human raters separately for each videoset (6 set) and feature (136 features)

features <- colnames(data[[1]])
features <- str_replace_all(features," ","_")
for(ki in khuman){
  print(paste("Calculating correlations, k = ",ki,sep = ""))
  
  # Initialize result matrices
  avgcorr_human_set <- matrix(0,ncol = 6,nrow = length(features))
  avgcorr_gpt_set <- matrix(0,ncol = 6,nrow = length(features))
  avgcorr_gpt_set_pval <- matrix(0,ncol = 6,nrow = length(features))
  for(set in seq(from=1,to=6)){
    
    # Images of this videoset
    images_set <- frames_human$V1[frames_human$videoset==set]
    images_set <- str_replace_all(images_set,".png","")
    
    # Which images we have in the GPT dataset
    images <- intersect(images_set,rownames(data_gpt))
    
    # Select the data for these images
    data_gpt_set <- data_gpt[images,]
    
    # Calculate the pairwise correlations and average correlations for this video set
    for(feat in seq(from=1,to=ncol(data_gpt_set))){
      
      # Load human data
      data_human <- read.csv(paste("/path/data_megaperception_frames_gpt41/data_frames_human_individual/",features[feat],"_",set,".csv",sep=""))
      rownames(data_human) <- images_set
      
      # Match data with the GTP dataset
      data_human_set <- data_human[images,]
      
      # Calculate the correlation between GPT and human average and check the p-value as well 
      cortest <- cor.test(data_gpt_set[,feat],rowMeans(data_human_set),method = "pearson",alternative = "greater",na.rm=T)
      avgcorr_gpt_set[feat,set] <- cortest$estimate
      avgcorr_gpt_set_pval[feat,set] <- cortest$p.value
      
      # Select the K left of human raters
      raters <- seq(from=1,by=1,to=ncol(data_human_set))
      k <- combn(raters,ki)
      
      # Correlations between the average of left out raters compared to the average of others (GPT ratings are not included in the average calculations)
      avgcorr_human_feat <- c()
      for(left_group in seq(from=1,by=1,to=ncol(k))){
        
        # Mean of the left out raters
        if(ki>1){
          mu_left <- rowMeans(data_human_set[,k[,left_group]],na.rm=T)
        }else{
          mu_left <- as.matrix(data_human_set[k[,left_group]])
        }
        
        # Mean of the other raters
        mu_others <- rowMeans(data_human_set[,setdiff(raters,k[,left_group])],na.rm=T)
        
        # Calculate the correlation between the two groups
        cortest_human <- cor.test(mu_left,mu_others,method = "pearson",na.rm=T)
        avgcorr_human_feat[left_group] <- cortest_human$estimate
      }
      
      # Store the the mean value over all possible combinations of groups (take Fischer transformation before calculating the mean)
      avgcorr_human_set[feat,set] <- tanh(mean(atanh(avgcorr_human_feat),na.rm = T))
    }
  }
  
  ##----------------------------------------------------------------------------------------------------------------------------------------------------------------
  # Save results
  
  # Take the average per videosets (take Fischer transformation before calculating the mean)
  avgcorr_gpt_mean <- tanh(rowMeans(atanh(avgcorr_gpt_set),na.rm = T))
  avgcorr_human_mean <- tanh(rowMeans(atanh(avgcorr_human_set),na.rm = T))
  
  # Calculate the aggregate p-value for each feature (https://www.nature.com/articles/s41598-021-8646y5-, Fischer's method)
  pvalues <- c()
  for(feat in seq(from=1,by=1,to=length(features))){
    pvals <- avgcorr_gpt_set_pval[feat,]
    pvals <- pvals[!is.na(pvals)]
    stat <- -2*sum(log(pvals))
    pvalues[feat] <- pchisq(stat, df = 2 * length(pvals), lower.tail = FALSE)
  }
  
  # Make data frames
  avgcorr <- as.data.frame(avgcorr_gpt_mean)
  rownames(avgcorr) <- features
  colnames(avgcorr) <- "gpt"
  
  # Human data is the same for each dataset, no need to save all
  avgcorr$human <- avgcorr_human_mean
  
  # Add the p-values
  avgcorr$gpt_pvalues <- pvalues
  
  # Save
  write.csv(avgcorr,paste("/path/results_megaperception_frames_gpt41/avgcorr_table_",ki,".csv",sep=""),row.names = T)
}

