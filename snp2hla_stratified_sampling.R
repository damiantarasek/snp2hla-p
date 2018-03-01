library(sampling)

# deal with arguments
args <- commandArgs(trailingOnly = TRUE)
famFile <- args[1]
keep_file <- args[2]
subsets <- as.numeric(args[3])
seed <- as.numeric(args[4])
	
# read fam file
fam <- read.table(file = famFile, header = FALSE)
fam <- subset(fam, select = c('V1','V2','V6'))
colnames(fam) <- c('ID','FID','CC')
fam$CC[fam$CC == "-9"] <- "2"
fam <- fam[order(fam$CC),]

# case and control number to sample - keep proportions to match original dataset
case_n <- sum(fam$CC == 2)
control_n <- sum(fam$CC == 1)

case_subset <- round(case_n/subsets)
control_subset <- round(control_n/subsets)

# stratified sampling
for (subset in 1:(subsets-1)){
  
  # for testing
  # status <- dim(fam)
  # print(status)
  # numbers <- table(fam$CC)
  # print(numbers)

  output_file <- paste(keep_file, ".", "keep", subset, sep = "")
  if (!is.null(seed)) set.seed(seed)
  samples <- strata(fam, "CC", size = c(control_subset,case_subset), method = "srswor")
  famKeep <- fam[samples$ID_unit,c(1:3)]
  write.table(famKeep, file = output_file, quote = FALSE, col.names = FALSE, row.names = FALSE)
  
  # remove samples from fam df
  fam <- fam[ ! fam$ID %in% famKeep$ID,]
  
}

# write remaining samples.
output_file <- paste(keep_file, ".", "keep", subsets, sep = "")
fam <- subset(fam, select=c('ID','FID','CC'))
write.table(fam, file = output_file, quote = FALSE, col.names = FALSE, row.names = FALSE)