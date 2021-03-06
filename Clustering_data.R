#Working with PC2

##how many genes do we use for clustering

#finding the most important genes (with the biggest influence). Therefore we will look at the loading scores 
#(saved in "rotation") of the genes on PC1. Because it's not important
#whether it is positive or negative we will look at the absolute values and rank these

loading_scores <- pca_m_values$rotation[, 2]
ranked_gene_loading <- sort(abs(loading_scores), decreasing = TRUE)

##loading plots with elbow method

plot(
  ranked_gene_loading,
  main = "Loading scores of genes",
  xlab = "Genes",
  ylab = "loading scores",
  type = "b"
)

#The kink is somewhere between 0 and 20000 genes, so lets zoom in

plot(
  ranked_gene_loading[0 : 5000],
  main = "Loading scores of genes",
  xlab = "Genes",
  ylab = "loading scores",
  type = "b"
)
abline(v = 2000,
col = "red",
lty = 5,
lwd = 2)


#We will work with the top 14000 genes 

clustering_matrix <- matrix(nrow = 10, ncol = 5)
rownames(clustering_matrix) <- c(
  "Bcell_naive_VB_NBC_NC11_41.M",
  "Bcell_naive_VB_NBC_NC11_83.M",
  "Bcell_naive_VB_S001JP51.M",
  "Bcell_naive_VB_S00DM851.M",
  "Bcell_naive_VB_S01ECGA1.M",
  "cancer_VB_S01FE8A1.M",
  "cancer_VB_S01FF6A1.M",
  "cancer_VB_S01FH2A1.M",
  "cancer_VB_S01FJZA1.M",
  "cancer_VB_S01FKXA1.M"
)

colnames(clustering_matrix) <- c(
  "1000 genes",
  "2000 genes",
  "3000 genes",
  "4000 genes",
  "5000 genes"
)

#for (i in 1 : 5) {
 # clustering_data <- rbind(m_values[c(as.list.data.frame(rownames(data.frame(ranked_gene_loading[1 : i*1000])))),])
  #k <-
   # kmeans(
    #  x = t(clustering_data),
     #       centers = 2,
      #      iter.max = 100
       #     )

  #clustering_matrix[, i] <- as.matrix(k$cluster)
#}

#pick out the names of the top 14000 genes
top_4000_genes <- data.frame(ranked_gene_loading[1 : 4000])

#get m values of top 14000 genes of every sample and put them into a new data frame
clustering_data <- rbind(m_values[c(as.list.data.frame(rownames(top_4000_genes))),])

#How many clusters do we need?
wss2 <-  sapply(1:5, function(k) {
  kmeans(x = clustering_data,
         centers = k,
         iter.max = 100)$tot.withinss
})
plot(
  1:5,
  wss2,
  type = "b",
  pch = 19,
  xlab = "Number of clusters K",
  ylab = "Total within-clusters sum of squares"
)

k <-
  kmeans(
    x = t(clustering_data),
    centers = 2,
    iter.max = 100
  )#$centers

View(k)  

#it seems like we need 2 clusters (kink in the curve)
##therefore we will go with 2 because our samples should only be put into 2 clusters (healthy/cancer)

##---------------maybe we should delete this following part or look up again how to plot k means clustering--------------------------------------

#find out if healthy and cancer samples are seperated
#variable with two center positions of value of rotated data


centers2 <- kmeans(
  x = clustering_data,
  centers = 2,
  iter.max = 100
)$centers

##adding an extra column with the category of sample with which we can color the pc dots in a ggplot according to their sample group
centers2 <-
  as.data.frame(t(data.frame(rbind(
    centers2,
    Samples = c(
      "Healthy",
      "Healthy",
      "Healthy",
      "Healthy",
      "Healthy",
      "Cancer",
      "Cancer",
      "Cancer",
      "Cancer",
      "Cancer"
    )
  ))))



p_cluster2 <- ggplot(centers2, aes(centers2$`1`, centers2$`2`, group = Samples))
p_cluster2 + geom_point (aes(color = Samples), size = 4) +
  theme_bw() 
p_cluster2 <- p_cluster2 + scale_colour_manual(values = c("seagreen2", "indianred2"))  

#-----------------------------------------------------------------------------------------------

#applying t test for each gene between the control and cancer groups, generating a p value matrix for each gene

#transposing the matrix for the t.test()
transposed_clustering_data <- as.data.frame(t(clustering_data))

p_value_each_gene <-
  sapply(1:ncol(transposed_clustering_data), function(k) {
   t.test(transposed_clustering_data[1:5, k],
           transposed_clustering_data[6:10, k],
           var.equal = T)$p.value
  })

p_value_each_gene <- as.data.frame(p_value_each_gene)


#--------------------------t test for important genes according to literature-----------------------------
#put clustering data of imortant genes into a new data frame to apply t test (unlist the list of important genes because with "c" we are expecting a vector)
clust_data_important_genes <- cbind(transposed_clustering_data[,c(unlist(important_genes))])

p_value_important_genes <-
  sapply(1:ncol(clust_data_important_genes), function(k) {
    t.test(clust_data_important_genes[1:5, k],
           clust_data_important_genes[6:10, k],
           var.equal = T)$p.value
  })

p_value_important_genes <- as.data.frame(cbind(important_genes, p_value_important_genes))

#--------------------------volcano plot------------------------------------------------------
#get beta values of top 4000 genes of every sample and put them into a new data frame
top_genes_beta_values <- rbind(healthy_beta_values[c(as.list.data.frame(rownames(top_4000_genes))),])
top_genes_beta_values <- cbind(top_genes_beta_values, cancer_beta_values[c(as.list.data.frame(rownames(top_4000_genes))),])

#calculate the mean beta values of cancer and healthy samples for each gene
top_genes_beta_values <- cbind(top_genes_beta_values, Mean_Healthy = log2(rowMeans(top_genes_beta_values[,1:5])), Mean_Cancer = log2(rowMeans(top_genes_beta_values[,6:10])))

#add column with differences of cancer and healthy means
top_genes_beta_values <- cbind(top_genes_beta_values, Mean_Difference = top_genes_beta_values[,11] - top_genes_beta_values[,12])

plot(x = top_genes_beta_values[,13], y = -log10(p_value_each_gene[,1]), xlab="log2 fold change", ylab="-log10 p-value")
#set threshold for p-values


#maybe mark the p values of the literature important genes by a different color#

# --------to do: adjust p values for multiple comparisons with p.adjust() Bonferroni-Holm ("BH") method

p_value_each_gene$BH <-  p.adjust(p_value_each_gene$p_value_each_gene, 
                                  method = "BH")
p_value_each_gene$bonferroni <-  p.adjust(p_value_each_gene$p_value_each_gene, 
                                  method = "bonferroni")
p_value_each_gene$holm <-  p.adjust(p_value_each_gene$p_value_each_gene, 
                                  method = "holm")
p_value_each_gene$hochberg <-  p.adjust(p_value_each_gene$p_value_each_gene, 
                                  method = "hochberg")
p_value_each_gene$hommel <-  p.adjust(p_value_each_gene$p_value_each_gene, 
                                  method = "hommel")
p_value_each_gene$BY <-  p.adjust(p_value_each_gene$p_value_each_gene, 
                                  method = "BY")

plot(p_value_each_gene)
#-> huge differences in adjustment of p values

#adding the rownames (gene names) to the matrix

p_value_each_gene$Names <- rownames(clustering_data)

# setting threshold for p-values to 0.05, and keeping the genes which fulfill this condition

p_value_each_gene <- p_value_each_gene[which(p_value_each_gene$BH < 0.05), ]

rownames(p_value_each_gene) <- p_value_each_gene$Names

#leaving only the genes which fulfill the threshhold condition in the clustering_data dataset, which their corresponding m-values

clustering_data <- clustering_data[c(rownames(p_value_each_gene)), ]


#findin top differentially methylated genes based on p-values and differences in mean m-values

# in an additional columns calculating mean m-value of healthy and cancer samples in clustering_data

#healthy

healthy_mean_m_values_diff_methylated <- as.matrix(
sapply(1:nrow(clustering_data), function(k) {
  rowMeans(clustering_data[k, 1:5])}))

#cancer

cancer_mean_m_values_diff_methylated <- as.matrix(
  sapply(1:nrow(clustering_data), function(k) {
    rowMeans(clustering_data[k, 6:10])}))

mean_values_together <- as.matrix(cbind(cancer_mean_m_values_diff_methylated, healthy_mean_m_values_diff_methylated))

#calculating abs difference

absolute_diff_m_values <- as.matrix(
  sapply(1:nrow(mean_values_together), function(k) {
    abs(diff(mean_values_together[k,]))}))
# p_values and mean m-value differences in one data frame

p_value_each_gene <- as.data.frame( cbind(p_value_each_gene, absolute_diff_m_values))

#finding diff methyalated genes based on 2 criteria: p_value < 1.5e-03 and mean m-value diff > 1.5

diff_methylated_genes <- p_value_each_gene[(p_value_each_gene$BH < 0.05) & (p_value_each_gene$absolute_diff_m_values > 5),]
dim(diff_methylated_genes)
