



###### First steps to load data and manage unhandy data #######
###############################################################

#Lea change environment
#setwd("C:/Users/Lea/Documents/Studium MoBi/4. Semester (SS 19)/Data Analysis Project/Git Hub/Dataset _ Mantle vs. B-cell")

#Load sample data
Samples <- readRDS(file = "Mantle-Bcell_list.RDS.gz")

#Loading annotation data file
input_data_csv <-
  read.csv(file = "sample_annotation.csv", sep = ",")

#copying "genes" data from general list to create a data frame of genes
Gene_data_frame <- Samples$genes
dim(Gene_data_frame)

#some pre-cleaning up: deleting x and y chromosome specific genes
Gene_data_frame_x_y <-
  Gene_data_frame[-which(Gene_data_frame$Chromosome == "chrX"),]
Gene_data_frame_x_y <-
  Gene_data_frame_x_y[-which(Gene_data_frame_x_y$Chromosome == "chrY"),]

#tidy up the data by spliting up the data to different data frame
healthy_coverage <- Gene_data_frame_x_y[, 21:25]
cancer_coverage <- Gene_data_frame_x_y[, 26:30]
healthy_beta_values <- Gene_data_frame_x_y[, 11:15]
cancer_beta_values <- Gene_data_frame_x_y[, 16:20]

####Coverage and Beta-Value problem####
#######################################

#mean and sd value histogram of every gene + quantiles
mean_cancer_coverage <- rowMeans(cancer_coverage)
hist(
  log10(mean_cancer_coverage),
  breaks = "fd",
  main = "Cancer coverage: Mean frequency",
  xlab = "Common logarithm of coverages",
  col = "indianred2",
  border = "gray20"
)
abline(
  v = log10(quantile(
    mean_cancer_coverage,
    probs = seq(0, 1, 0.1),
    na.rm = TRUE
  )),
  col = "black",
  lty = 5,
  lwd = 1
)

mean_healthy_coverage <- rowMeans(healthy_coverage)
hist(
  log10(mean_healthy_coverage),
  breaks = "fd",
  main = "Healthy coverage: Mean frequency",
  xlab = "Common logarithm of coverages",
  col = "seagreen2",
  border = "gray20"
)
abline(
  v = log10(quantile(
    mean_healthy_coverage,
    probs = seq(0, 1, 0.1),
    na.rm = TRUE
  )),
  col = "black",
  lty = 5,
  lwd = 1
)

sd_cancer_coverage <- apply(cancer_coverage, 1, sd)
hist(
  log10(sd_cancer_coverage),
  breaks = "fd",
  main = "Cancer coverage: SD frequency",
  xlab = "Common logarithm of coverages",
  col = "indianred2",
  border = "gray20"
)
abline(
  v = log10(quantile(
    sd_cancer_coverage,
    probs = seq(0, 1, 0.1),
    na.rm = TRUE
  )),
  col = "black",
  lty = 5,
  lwd = 1
)

sd_healthy_coverage <- apply(healthy_coverage, 1, sd)
hist(
  log10(sd_healthy_coverage),
  breaks = "fd",
  main = "Healthy coverage: SD frequency",
  xlab = "Common logarithm of coverages",
  col = "seagreen2",
  border = "gray20"
)
abline(
  v = log10(quantile(
    sd_healthy_coverage,
    probs = seq(0, 1, 0.1),
    na.rm = TRUE
  )),
  col = "black",
  lty = 5,
  lwd = 1
)
#include mean and sd column to cancer and healthy data set

#cancer_coverage <-  cbind(cancer_coverage, mean_cancer_coverage)
#healthy_coverage <- cbind(healthy_coverage, mean_healthy_coverage)

#cancer_coverage <- cbind(cancer_coverage, sd_cancer_coverage)
#healthy_coverage <- cbind(healthy_coverage, sd_healthy_coverage)

####find coverage value for threshold and remove coverages in threshold --> don't loose more than 90% of information

sum(cancer_coverage == 0) #not in markdown
sum(healthy_coverage == 0)  #not in markdown
#cancer coverages: lower boundary
threshold_cancer_lower <-
  quantile(mean_cancer_coverage,
           probs = 0.05,
           na.rm = TRUE)

#cancer coverages: upper boundary
threshold_cancer_upper <-
  quantile(mean_cancer_coverage,
           probs = 0.999,
           na.rm = TRUE)

#healthy coverages: lower boundary
threshold_healthy_lower <-
  quantile(mean_healthy_coverage,
           probs = 0.05,
           na.rm = TRUE)

#healthy coverages: upper boundary
threshold_healthy_upper <-
  quantile(mean_healthy_coverage,
           probs = 0.999,
           na.rm = TRUE)

##define a function to set every value of cancer coverage and cancer beta value to NA if they are in threshold and apply for the entire dataframe

cancer_threshold_function <- function(cancer_coverage) {
  if(cancer_coverage <= threshold_cancer_lower) {
    return("NA")}
  else {return(cancer_coverage)}
  
  if(cancer_coverage >= threshold_cancer_upper) {
    return("NA")}
  else{return(cancer_coverage)}
}

cancer_coverage <- apply(cancer_coverage, MARGIN = c(1,2), FUN = cancer_threshold_function)

## for later consideration: merge data frames coverage and beta values to substitute the for loop with the apply function
##thereafter remove covergae column

cancer_beta_values[cancer_coverage == "NA"] <- NA
cancer_coverage[cancer_coverage == "NA"] <- NA 


##define a function to set every value of healthy coverage and healthy beta value to NA if they are in threshold and apply for the entire dataframe
healthy_threshold_function <- function(healthy_coverage) {
  if(healthy_coverage <= threshold_healthy_lower) {
    return("NA")}
  else {return(healthy_coverage)}
  
  if(healthy_coverage >= threshold_healthy_upper) {
    return("NA")}
  else{return(healthy_coverage)}
}

healthy_coverage <- apply(healthy_coverage, MARGIN = c(1,2), FUN = healthy_threshold_function)

healthy_beta_values[healthy_coverage == "NA"] <- NA
healthy_coverage[healthy_coverage == "NA"] <- NA

remove(list = c("threshold_cancer_lower", "threshold_cancer_upper", "threshold_healthy_lower", "threshold_healthy_upper"))


#deal with NA's
##output of the number of all NA's in healthy genes
sum(is.na(cancer_beta_values))
sum(is.na(healthy_beta_values))

##add a new column with the number of NA's per gene
cancer_beta_values$Number_of_NA_cancer <-
  rowSums(is.na(cancer_beta_values))
cancer_beta_values$Number_of_NA_healthy <-
  rowSums(is.na(healthy_beta_values))

healthy_beta_values$Number_of_NA_healthy <-
  rowSums(is.na(healthy_beta_values))
healthy_beta_values$Number_of_NA_cancer <-
  rowSums(is.na(cancer_beta_values))
#NA_healthy_beta_values <- rowSums(is.na(healthy_beta_values))
#NA_cancer_beta_values <- rowSums(is.na(cancer_beta_values))

##Histogram of NA's
#cancer
ggplot() +
  geom_bar(
    data = cancer_beta_values,
    mapping = aes(x = cancer_beta_values$Number_of_NA_cancer),
    fill = "indianred2"
  ) +
  xlim(-0.5, 5.5) +
  ggtitle("NA's per Gene in cancer samples") +
  labs(x = "Number of NA's", y = "Number of Genes") +
  theme(plot.title = element_text(
    color = "black",
    size = 14,
    face = "bold",
    hjust = 0.5
  )) 

ggplot() +
  geom_bar(
    data = cancer_beta_values,
    mapping = aes(x = cancer_beta_values$Number_of_NA_cancer),
    fill = "indianred2"
  ) +
  xlim(0.5, 5.5) +
  ggtitle("NA's per Gene in cancer samples \n (zoomed in)") +
  labs(x = "Number of NA's", y = "Number of Genes") +
  theme(plot.title = element_text(
    color = "black",
    size = 14,
    face = "bold",
    hjust = 0.5
  )) 

#healthy
ggplot() +
  geom_bar(
    data = healthy_beta_values,
    mapping = aes(x = healthy_beta_values$Number_of_NA_healthy),
    fill = "indianred2"
  ) +
  xlim(-0.5, 5.5) +
  ylim(0, 50000) +
  ggtitle("NA's per Gene in healthy samples") +
  labs(x = "Number of NA's", y = "Number of Genes") +
  theme(plot.title = element_text(
    color = "black",
    size = 14,
    face = "bold",
    hjust = 0.5
  )) 
  
ggplot() +
  geom_bar(
    data = healthy_beta_values,
    mapping = aes(x = healthy_beta_values$Number_of_NA_healthy),
    fill = "indianred2"
  ) +
  xlim(0.5, 5.5) +
  ggtitle("NA's per Gene in healthy samples \n (zoomed in)") +
  labs(x = "Number of NA's", y = "Number of Genes") +
  theme(plot.title = element_text(
    color = "black",
    size = 14,
    face = "bold",
    hjust = 0.5
  )) 


#set a threshold for the NA values and remove the gene if there are too much NA's
cancer_beta_values <-
  cancer_beta_values[-which(
    cancer_beta_values$Number_of_NA_cancer >= 3 |
      cancer_beta_values$Number_of_NA_healthy >= 3
  ), ]
healthy_beta_values <-
  healthy_beta_values[-which(
    healthy_beta_values$Number_of_NA_cancer >= 3 |
      healthy_beta_values$Number_of_NA_healthy >= 3
  ), ]

#check if genes of one data frame are in the other data frame
sum(rownames(healthy_beta_values) != rownames(cancer_beta_values))

##remove column Number_of_NA
cancer_beta_values <-
  cancer_beta_values[, -which(
    colnames(cancer_beta_values) %in% c("Number_of_NA_cancer", "Number_of_NA_healthy")
  )]

healthy_beta_values <-
  healthy_beta_values[, -which(
    colnames(healthy_beta_values)  %in%  c("Number_of_NA_cancer", "Number_of_NA_healthy")
  )]

#replace remaining NA's with the mean of the respective gene
#first transposing the data frame because working on columns, e.g getting the mean, is easier than with rows
transposed_cancer_beta_values <- t(cancer_beta_values)
transposed_healthy_beta_values <- t(healthy_beta_values)

#how many elements do we have in our new data frame?
dim(transposed_healthy_beta_values)
dim(transposed_cancer_beta_values)

#going through all elements of the (already reduced) data frame and replace NA's with mean
for (i in 1:ncol(transposed_cancer_beta_values)) {
  transposed_cancer_beta_values[is.na(transposed_cancer_beta_values[, i]), i] <-
    mean(transposed_cancer_beta_values[, i], na.rm = TRUE)
}

for (i in 1:ncol(transposed_healthy_beta_values)) {
  transposed_healthy_beta_values[is.na(transposed_healthy_beta_values[, i]), i] <-
    mean(transposed_healthy_beta_values[, i], na.rm = TRUE)
}

#did we eliminate all NA's?
sum(is.na(transposed_healthy_beta_values))
sum(is.na(transposed_cancer_beta_values))

#retranspose to data frame
healthy_beta_values <- data.frame(t(transposed_healthy_beta_values))
cancer_beta_values <- data.frame(t(transposed_cancer_beta_values))

remove(list = c(
  "transposed_cancer_beta_values",
  "transposed_healthy_beta_values"
))

#are important genes still included?
important_genes <-
  data.frame(
    c(
      "ENSG00000176887",
      "ENSG00000185551",
      "ENSG00000141510",
      "ENSG00000110092",
      "ENSG00000106546",
      "ENSG00000169855",
      "ENSG00000125398",
      "ENSG00000078399",
      "ENSG00000039068",
      "ENSG00000081377",
      "ENSG00000054598",
      "ENSG00000123689",
      "ENSG00000211445",
      "ENSG00000131981",
      "ENSG00000172005",
      "ENSG00000106236",
      "ENSG00000007372",
      "ENSG00000105825",
      "ENSG00000159445",
      "ENSG00000122691"
    )
  )

##we only have to check one data set because cancer and healthy have the same genes
important_genes_in_data_set <- data.frame()
for (i in 1:nrow(important_genes)) {
  important_genes_in_data_set[i,] <-
    cancer_beta_values[which(row.names(cancer_beta_values) == important_genes[i,]),]
}

##look up if there are NAs --> would be bad
sum(is.na(important_genes_in_data_set))

##hurray no NAs

remove(important_genes_in_data_set)
