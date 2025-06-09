# Compare the social perceptual evaluations between GPT4 Vision and humans in the video data

# Severi Santavirta 28.5.2025

library(corrplot)
library(stringr)
library(lessR)
library(ggplot2)
library(ggpubr)
library(ggrepel)
library(psych)
library(ape)

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

load("/path/data_megaperception_clips/processed_data_5batches.RData")
features <- colnames(data[[1]])
data_list_gpt <- data

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Match human data with GPT

# Analyze only rows that we have in each data (some videos failed in GPT data)
common_rows <- Reduce(intersect, list(rownames(data[[1]]),rownames(data_nonzero_human)))
data_nonzero_human <- data_nonzero_human[common_rows,]
colnames(data_nonzero_human) <- features

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Correlation between the raw ratings between human average and GPT datasets (over all features for each dataset)

r_raw <- matrix(NA,nrow = length(data_list_gpt),ncol = 1)
for(dataset in seq(from=1,to=length(data_list_gpt))){
  
  # Select the dataset
  data_gpt <- data_list_gpt[[dataset]]
  
  # Vectorize and combine
  combined_data <- as.data.frame(as.numeric(unlist(data_gpt)))
  colnames(combined_data) <- 'gpt_value'
  combined_data$human_value <- as.numeric(unlist(data_nonzero_human))
  
  # Calculate overall correlation over all features
  r_raw[dataset] <- cor(combined_data$gpt_value,combined_data$human_value)
  
}

# Plot the correlation for each dataset
r_raw <- as.data.frame(r_raw)
colnames(r_raw) <- "corr"
r_raw$idx <- 1:31
r_raw$group <- as.factor(c(1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,5))

pdf("/path/results_megaperception_clips/correlation_raw_improvement.pdf",height = 5,width = 5)
ggplot(r_raw,aes(y=corr,x=idx,color = group)) +
  geom_point(size = 3) +
  ylim(0.5,0.65) +
  theme_minimal()
dev.off()

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Correlation between the raw ratings between human average and GPT for each feature separately in the final dataset. Calculate p-values as well

r_feature <- matrix(NA,nrow = length(features),2)
data_gpt <- data_list_gpt[[length(data_list_gpt)]]
for(feat in seq(from=1,by=1,to=length(features))){
  cortest <- cor.test(data_gpt[,feat],data_nonzero_human[,feat],method = "pearson",alternative = "greater")
  r_feature[feat,1] <- cortest$estimate
  r_feature[feat,2] <- cortest$p.value
}

r_feature <- as.data.frame(r_feature)
rownames(r_feature) <- features
colnames(r_feature) <- c("r","pval")

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Inter rater reliability between GPT rounds using ICC

iccs <- c()
for(feat in seq(from=1,to=ncol(data_list_gpt[[1]]))){
  feat_data <- cbind(data_list_gpt[[1]][,feat],data_list_gpt[[2]][,feat],data_list_gpt[[3]][,feat],data_list_gpt[[4]][,feat],data_list_gpt[[5]][,feat])
  res <- ICC(feat_data)
  iccs[feat] <- res$results$ICC[2]
}

iccs <- as.data.frame(iccs)
iccs$features <- features
write.csv(iccs,"/path/results_megaperception_clips/iccs_between_gpt_rounds.csv")

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Plot the scatterplot over all social features

# Vectorize and combine
combined_data <- as.data.frame(as.numeric(unlist(data_list_gpt$`1,2,3,4,5`)))
colnames(combined_data) <- 'gpt_value'
combined_data$human_value <- as.numeric(unlist(data_nonzero_human))

# Normalize values between 0 and 10 for plotting
combined_data$gpt_value <- ((combined_data$gpt_value - 0) / (100 - 0))*10
combined_data$human_value <- ((combined_data$human_value - 0) / (100 - 0))*10

# Scatterplot over all features 
pdf("/path/results_megaperception_clips/scatterplot_socialfeatures.pdf",width = 8, height = 8)
ggplot(combined_data,aes(x = human_value, y = gpt_value)) +
  geom_hex(bins = 25, aes(fill = ..density.., alpha = ..density..),show.legend = FALSE) +
  scale_fill_gradientn(colors = c("blue","red")) +
  scale_alpha_continuous(range = c(0.1,20)) + # Adjust the range as needed
  theme_minimal() +
  coord_cartesian(xlim = c(0, 10), ylim = c(0, 10)) +
  labs(x = "Human average", y = "GPT-4V", title = "Videos") +
  theme(axis.title = element_text(size=28),
        plot.title = element_text(hjust = 0.5, size = 32),
        axis.text.x = element_text(size = 24),  # Adjust x-axis tick size
        axis.text.y = element_text(size = 24),
        legend.position = "none") +
  geom_abline(slope = 1, intercept = 0, color = "black", size= 3)
dev.off()

# Calculate overall correlation over all features
r_overall <- cor(combined_data$gpt_value,combined_data$human_value)

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Scatterplot the feature specific correlations against the correlations between humans. Plot separately for each k (k: Number of humans to be left out from the calculation)

k = c(1,2,3,4,5)
avgcor_gpt_better <- matrix(NA,nrow = length(k),ncol = 4)
require(lattice)
for(ki in k){
  
  avg_data <- read.csv(paste("/path/results_megaperception_clips/avgcorr_table_",ki,".csv",sep=""))
  avg_data$X <- str_replace_all(avg_data$X,"_", " ") 
  
  # Scatterplot
  p <- ggplot(avg_data, aes(x=human, y=gpt,label = X)) + 
    geom_point(size=2) +
    geom_text_repel(box.padding = 0.3, max.overlaps = Inf,size = 5,segment.size = 0.1) +
    geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red") +  # Add y = x line
    ylab("Agreement of GPT-4V") +
    xlab("Intersubject consistency") +
    scale_x_continuous(limits = c(0.0,1)) +
    scale_y_continuous(limits = c(0.0,1)) +
    theme_minimal() +
    theme(axis.title = element_text(size=24),
          axis.text = element_text(size=20))
  
  pdf(paste("/path/results_megaperception_clips/scatterplot_avgcorr_",ki,".pdf",sep=""),width = 20,height = 10)
  print(p)
  dev.off()
  
  # For how many features the GPT exceeds individual humans ratings?
  avgcor_gpt_better[ki,1] <- sum(avg_data$gpt > avg_data$human) # Raw
  avgcor_gpt_better[ki,2] <- sum(avg_data$gpt > avg_data$human)/nrow(avg_data) # Percentage
  avgcor_gpt_better[ki,3] <- tanh(mean(atanh(avg_data$gpt))) # Mean cor GPT
  avgcor_gpt_better[ki,4] <- tanh(mean(atanh(avg_data$human))) # Mean cor human
}

avgcor_gpt_better <- as.data.frame(avgcor_gpt_better)
colnames(avgcor_gpt_better) <- c("gpt_better","gpt_better_perc","gpt_avgcor","human_avgcor")

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Similarities of the clustering results

# Order both matrices based on the HUMAN clustering result

# Calculate correlation matrices
cormat_human <- cor(data_nonzero_human)
cormat_gpt <- cor(data_list_gpt$`1,2,3,4,5`)

# Cluster the human correlation matrix hierarchically
cormat_human_ordered <- corReorder(cormat_human,order = "hclust",hclust_type = "average")

# Order the frame correlation matrices based on the previously ordered video based cormat
cormat_gpt_ordered <- cormat_gpt[colnames(cormat_human_ordered),colnames(cormat_human_ordered)]

# Plot the matrices
pdf("/path/results_megaperception_clips/gpt_cormat_ordered_by_human_clustering.pdf",width = 20,height = 20)
corrplot(cormat_gpt_ordered, tl.col = "black", col.lim = c(-1, 1), method = "color",col=colorRampPalette(c("#2166AC","#4393C3","#92C5DE","#D1E5F0","#FDDBC7","#F4A582","#D6604D","#B2182B"))(20),type = "upper",tl.pos = 'n')
dev.off()
pdf("/path/results_megaperception_clips/human_cormat_ordered_by_human_clustering.pdf",width = 20,height = 20)
corrplot(cormat_human_ordered, tl.col = "black", col.lim = c(-1, 1), method = "color",col=colorRampPalette(c("#2166AC","#4393C3","#92C5DE","#D1E5F0","#FDDBC7","#F4A582","#D6604D","#B2182B"))(20),type = "lower",tl.pos = 'n')
dev.off()

# Calculate the correlation between the matrices
lower_idx_human <- lower.tri(cormat_human_ordered)
lower_idx_gpt<- lower.tri(cormat_gpt_ordered)
lower_triangle_human <- cormat_human_ordered[lower_idx_human]
lower_triangle_gpt <- cormat_gpt_ordered[lower_idx_gpt]
correlation_gpt_human <- cor(lower_triangle_gpt,lower_triangle_human)

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Mantel test for the similarity of the clustering results between GPT-4V and human correlation matrices

test_cormat <- mantel.test(cormat_human_ordered,cormat_gpt_ordered,nperm = 1000000, graph = T,alternative = "greater")

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Similarities of the PCoA results

# Select Pearson correlation distance as distance measure
distance_gpt <- 1-cor(data_list_gpt$`1,2,3,4,5`)
distance_human <- 1-cor(data_nonzero_human)

# Run PCoA
fit_human <- cmdscale(distance_human,eig=TRUE,k=(ncol(distance_human)-1))
fit_gpt <- cmdscale(distance_gpt,eig=TRUE,k=(ncol(distance_gpt)-1))
loadings_human <- fit_human$points
loadings_gpt <- fit_gpt$points
weights_human <- fit_human$eig
weights_gpt <- fit_gpt$eig
var_exp_human <- weights_human[weights_human>0]/sum(weights_human[weights_human>0])
var_exp_gpt <- weights_gpt[weights_gpt>0]/sum(weights_gpt[weights_gpt>0])

# Take the first 20 components (8 significant PCs were identified for the movie data in the original experiment, but we plot more to highlight that there correlation get weak in th latter components)
loadings_human <- loadings_human[,1:20]
loadings_gpt <- loadings_gpt[,1:20]

# Names for plotting
cats_human <- c("Human PC1","Human PC2","Human PC3","Human PC4","Human PC5","Human PC6","Human PC7","Human PC8","Human PC9","Human PC10","Human PC11","Human PC12","Human PC13","Human PC14","Human PC15","Human PC16","Human PC17","Human PC18","Human PC19","Human PC20")
cats_gpt <- c("GPT PC1","GPT  PC2","GPT  PC3","GPT  PC4","GPT  PC5","GPT  PC6","GPT  PC7","GPT PC8","GPT PC9","GPT  PC10","GPT  PC11","GPT  PC12","GPT  PC13","GPT  PC14","GPT  PC15","GPT PC16","GPT PC17","GPT  PC18","GPT  PC19","GPT  PC20") 
colnames(loadings_human) <- cats_human
colnames(loadings_gpt) <- cats_gpt

# Plot a correlation matrix where human is rows and GPT is columns
cormat <- matrix(0,nrow = 20,ncol = 20)
pmat <- matrix(0,nrow = 20,ncol = 20)
for(i in seq(from=1,to=20)){
  for(j in seq(from=1,to=20)){
    cormat[i,j] <- abs(cor(loadings_human[,i],loadings_gpt[,j]))
    test <- cor.mtest(cbind(loadings_human[,i],loadings_gpt[,j]),conf.level = 0.95)
    pmat[i,j] <- test$p[1,2]
  }
}
cats <- c("PC1","PC2","PC3","PC4","PC5","PC6","PC7","PC8","PC9","PC10","PC11","PC12","PC13","PC14","PC15","PC16","PC17","PC18","PC19","PC20")
rownames(cormat) <- cats
colnames(cormat) <- cats
rownames(pmat) <- cats
colnames(pmat) <- cats

pdf("/path/results_megaperception_clips/PCoA_comparison_gpt_mean.pdf",width = 8,height = 8)
corrplot(cormat,p.mat = pmat,insig = 'blank',sig.level = 0.001,is.corr = FALSE,method = "square",tl.col = 'black')
dev.off()

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Save human and GPT data for fMRI analysis

write.csv(data_gpt,"/path/data_megaperception_clips/data_gpt_5batches_28052025.csv",row.names = T)
write.csv(data_nonzero_human,"/path/data_megaperception_clips/data_human_28052025.csv",row.names = T)
