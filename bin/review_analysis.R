# Get system time to print total run time
st <- proc.time()
cat("Running review_analysis.R\n")

# set options to print warnings as they appear
options(warn=1)

# install archived pacakges.
# uncomment to install
# download.file("http://cran.cnr.berkeley.edu/src/contrib/Archive/Rstem/Rstem_0.4-1.tar.gz", "Rstem_0.4-1.tar.gz") 
# install.packages("Rstem_0.4-1.tar.gz", repos=NULL, type="source")
# download.file("http://cran.r-project.org/src/contrib/Archive/sentiment/sentiment_0.2.tar.gz", "sentiment.tar.gz")
# install.packages("sentiment.tar.gz", repos=NULL, type="source")

# import libraries
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(tm))
suppressPackageStartupMessages(library(wordcloud))
suppressPackageStartupMessages(library(plyr))
suppressPackageStartupMessages(library(scales))
suppressPackageStartupMessages(library(sentiment))

# handle arguments of company [1] and bash script path [2]
args <- commandArgs(TRUE)
company <- args[1]
review.data <- paste(args[2], "/output/reviews/", company, ".reviews", sep="")
company.plots <- paste(args[2], "/figs/", company, ".output.pdf", sep="")

# write header to log
cat(sprintf("R Analysis of %s on %s\n", company, date()))

# read in reviews
txt <- readLines(review.data)

# print info to log
cat(sprintf("%s reviews file has %d rows\n", company, length(txt)))

# initialize empty words string to store text of reviews
words <- c()

# populate rating vector and data frame
for (i in 1:length(txt))
{
  if (substr(txt[i], 1, 7) != "Version")
  {
    words <- c(words, txt[i])
  }
}

# used this reference
# https://sites.google.com/site/miningtwitter/questions/sentiment/sentiment

# clean up documents
# remove punctuation
words <- gsub("[[:punct:]]", "", words)

# remove numbers
words <- gsub("[[:digit:]]", "", words)

# remove unnecessary spaces
words <- gsub("[ \t]{2,}", " ", words)
words <- gsub("[ \t]{2,}", "", words)

# lower case using try.error with sapply 
words <- tolower(words)

# classify polarity
class_pol <- classify_polarity(words, algorithm="bayes")

# adjust "tolerance" of positive, negative, neutral
polarity <- class_pol[,3]
pos_ids <- polarity > 2.3
neg_ids <- polarity < 0.7
neut_ids <- !(pos_ids | neg_ids)

polarity[pos_ids] <- "Positive"
polarity[neg_ids] <- "Negative"
polarity[neut_ids] <- "Neutral"

# data frame with results
sent_df <- data.frame(text=words, polarity=polarity, stringsAsFactors=FALSE)

# separating text by emotion
pols <- c("Positive", "Negative", "Neutral")
npols <- 3
pol.docs <- rep("", npols)

for (i in 1:npols)
{
  tmp <- words[polarity == pols[i]]
  pol.docs[i] <- paste(tmp, collapse=" ")
}

# remove stopwords
pol.docs = removeWords(pol.docs, stopwords("english"))

# create corpus
corpus = Corpus(VectorSource(pol.docs))
tdm = TermDocumentMatrix(corpus)
tdm = as.matrix(tdm)
colnames(tdm) = pols

matter_colors <- c("#558C43", "#DD0C39", "#646464")

# write wordcloud to pdf
pdf(company.plots)
suppressWarnings(comparison.cloud(tdm, colors = matter_colors, 
                                  title.size = 1,
                                  max.words=min(nrow(tdm), 100), 
                                  scale = c(2,0.15)))
dev.off()

# if there were no warnings right success message to long
# else write error message
if (is.null(warnings()) == TRUE)
{
  cat("There were no warnings\n")
} else
{
  cat("There were warnings in the program\n")
}

# write total run time to log
print(proc.time() - st)
