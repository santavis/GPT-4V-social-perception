# Compare the social perceptual evaluations between GPT4 Vision and humans in the frame perception data

# Severi Santavirta 14.5.2024

library(corrplot)
library(stringr)
library(lessR)
library(diceR)
library(corrplot)
library(ggplot2)
library(ggpubr)
library(ggrepel)
library(psych)
library(ape)

pearson <- function(x) {
  x %>%
    t() %>%
    stats::cor(method = "pearson") %>%
    magrittr::subtract(1, .) %>%
    magrittr::extract(lower.tri(.)) %>%
    `attributes<-`(
      list(
        Size = nrow(x),
        Labels = rownames(x),
        Diag = FALSE,
        Upper = FALSE,
        methods = "pearson",
        class = "dist"
      )
    )
}

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Process human data

# Read human data
load('path/data_frames_human.RData')
data_nonzero_human <- data

# Load frame order (data are saved in spreadsheet order and from the PicDips1 to PicDisp6)
frames_human <- read.csv('path/frame_order.csv')
frames_human <- frames_human$V1
frames_human <- str_replace_all(frames_human,".png","")
rownames(data_nonzero_human) <- frames_human

# Sort alphabetically
data_nonzero_human <- data_nonzero_human[order(rownames(data_nonzero_human)),]

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Load preprocessed GPT data

load("path/processed_data_5batches.RData")
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

# Figure SI-3: Plot the average correlation between human mean and different GPT round by the data index
correlations_mean <- colMeans(correlations_raw)
correlations_mean <- as.data.frame(correlations_mean)
colnames(correlations_mean) <- "corr"
correlations_mean$idx <- 1:31
correlations_mean$group <- as.factor(c(1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,5))

pdf("path/correlation_raw_improvement.pdf",height = 5,width = 5)
ggplot(correlations_mean,aes(y=corr,x=idx,color = group)) +
  geom_point(size = 3) +
  ylim(0.5,0.6) +
  theme_minimal()
dev.off()

# Featurewise correlations
correlations_raw <- as.data.frame(correlations_raw)
rownames(correlations_raw) <- features
colnames(correlations_raw) <- names(data)

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Inter-rater reliability between GPT rounds using ICC

iccs <- c()
for(feat in seq(from=1,to=ncol(data[[1]]))){
  feat_data <- cbind(data[[1]][,feat],data[[2]][,feat],data[[3]][,feat],data[[4]][,feat],data[[5]][,feat])
  res <- ICC(feat_data)
  iccs[feat] <- res$results$ICC[2]
}

iccs <- as.data.frame(iccs)
iccs$features <- features
write.csv(iccs,"path/iccs_between_gpt_rounds.csv")

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Scatterplot the correlation with the human average against any individual human or GPT (Figure 2)

avg_data <- read.csv("path/avgcorr_table.csv")
avg_data$X <- str_replace_all(avg_data$X,"_", " ") 

# Scatterplot
pdf("path/scatterplot_avgcorr.pdf",width = 20,height = 10)
ggplot(avg_data, aes(x=avg_data$human, y=avg_data$X1.2.3.4.5,label = avg_data$X)) + 
  geom_point(size=1) +
  geom_text_repel(box.padding = 0.1, max.overlaps = Inf,size = 5) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red") +  # Add y = x line
  ylab("GPT-4V-to-human average correlation") +
  xlab("Human-to-human average correlation") +
  scale_x_continuous(limits = c(0.05, 0.95)) +
  scale_y_continuous(limits = c(0.05, 0.95)) +
  theme_minimal() +
  theme(axis.title = element_text(size=24))
dev.off()

# For how many reatures the GPT exceeds indivisual humans ratigns?
avgcor_gpt_better <- sum(avg_data$X1.2.3.4.5 > avg_data$human)
avgcor_gpt_better_perc <- sum(avg_data$X1.2.3.4.5 > avg_data$human)/nrow(avg_data)

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Similarities of the consensus clustering results

# Cluster human data
CC <- consensus_cluster(t(data_nonzero_human), nk = 5:40, p.item = 0.8, reps = 1000, algorithms = c("hc"),distance = c("pearson"),scale = FALSE)
m_trim_human <- consensus_matrix(CC)
rownames(m_trim_human) <- colnames(data_nonzero_human)
colnames(m_trim_human) <- colnames(data_nonzero_human)

# Cluster GPT data
CC <- consensus_cluster(t(data$`1,2,3,4,5`), nk = 5:40, p.item = 0.8, reps = 1000, algorithms = c("hc"),distance = c("pearson"),scale = FALSE)
m_trim_gpt <- consensus_matrix(CC)
rownames(m_trim_gpt) <- colnames(data$`1,2,3,4,5`)
colnames(m_trim_gpt) <- colnames(data$`1,2,3,4,5`)

# Save/load results
save(list = c("m_trim_human","m_trim_gpt"), file = "path/consensus_clustering_analyses.RData")
load("path/consensus_clustering_analyses.RData")

# Correlation matrices
cormat_human <- cor(data_nonzero_human)
cormat_gpt <- cor(data$`1,2,3,4,5`)

# Order the human correlation matrix by the consensus clustering result
m_trim_human_ordered <- corReorder(m_trim_human,order = "hclust",hclust_type = "average")

# Next, order human and GPT correlation matrices based on human consensus results, plot them and calculate their correlation (Figure 3)
cormat_human_ordered_by_human <- cormat_human[colnames(m_trim_human_ordered),colnames(m_trim_human_ordered)]
cormat_gpt_ordered_by_human <- cormat_gpt[colnames(m_trim_human_ordered),colnames(m_trim_human_ordered)]
pdf("path/gpt_cormat_ordered_by_human_consensus_clustering.pdf",width = 20,height = 20)
corrplot(cormat_gpt_ordered_by_human, tl.col = "black", col.lim = c(-1, 1), method = "square",col=colorRampPalette(c("#2166AC","#4393C3","#92C5DE","#D1E5F0","#FDDBC7","#F4A582","#D6604D","#B2182B"))(20),type = "upper",tl.pos = 'n')
dev.off()
pdf("path/human_cormat_ordered_by_human_consensus_clustering.pdf",width = 20,height = 20)
corrplot(cormat_human_ordered_by_human, tl.col = "black", col.lim = c(-1, 1), method = "square",col=colorRampPalette(c("#2166AC","#4393C3","#92C5DE","#D1E5F0","#FDDBC7","#F4A582","#D6604D","#B2182B"))(20),type = "lower",tl.pos = 'n')
dev.off()

# Calculate the correlation between the matrices
lower_idx_human <- lower.tri(cormat_human_ordered_by_human)
lower_idx_gpt<- lower.tri(cormat_gpt_ordered_by_human)
lower_triangle_human <- cormat_human_ordered_by_human[lower_idx_human]
lower_triangle_gpt <- cormat_gpt_ordered_by_human[lower_idx_gpt]
correlation_gpt_human <- cor(lower_triangle_gpt,lower_triangle_human)

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
### Mantel test for the similarity of the clustering results between GPT-4V and human correlation matrices

test_cormat <- mantel.test(cormat_human_ordered_by_human,cormat_gpt_ordered_by_human,nperm = 1000000, graph = T,alternative = "greater")

##-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Similarities of the PCoA results

# Select Pearson correlation distance as distance measure
distance_gpt <- 1-cor(data$`1,2,3,4,5`)
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

# Plot a correlation matrix where Human is rows and GPT is columns
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

# Figure 3
pdf("path/PCoA_comparison_gpt_mean.pdf",width = 8,height = 8)
corrplot(cormat,p.mat = pmat,insig = 'blank',sig.level = 0.01,is.corr = FALSE,method = "square",tl.col = 'black')
dev.off()

