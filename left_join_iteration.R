library(readr)
library(dplyr)
#arguments processing
args <- commandArgs(trailingOnly = TRUE)
file1 <- args[1]
file2 <- args[2]
#read df
sample_header <- c('id','prob')
s1 <- read_delim(file1, delim = '\t', col_names =  sample_header)
s2 <- read_delim(file2, delim = '\t', col_names =  sample_header)
sample <- s1
sample <- left_join(s1, s2, by = c('id'))
#average
sample$average <- rowMeans(data.frame(sample$prob.x, sample$prob.y), na.rm = TRUE)
sample$average <- round(sample$average, 3)
# write sample sheet
write_delim(sample[,c("id","average")], file1, append = FALSE, col_names = FALSE, delim = '\t')
#write_delim(sample[,c("id","average")], "snp2hla/temp_output/r2.average.txt", append = FALSE, col_names = FALSE, delim = '\t')  