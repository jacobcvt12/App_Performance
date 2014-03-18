# Get system time to print total run time
st <- proc.time()
print("Running review_analysis.R")

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

# empty vector to store ratings in
ratings <- c()

# initialize empty words string to store text of reviews
words <- c()

# guess how many reviews there are and prepopulate data frame for speed
pre_rows <- ceiling(length(txt) / 2)

# create data frame to store info
ver.rel.mod.ratings <- data.frame("Version"=character(pre_rows), 
                                  "Rating"=integer(pre_rows), 
                                  "Count"=integer(pre_rows), 
                                  stringsAsFactors=FALSE)

# use k as index for rows, since not all text rows have Ratings
k <- 1

# populate rating vector and data frame
for (i in 1:length(txt))
{
  if (substr(txt[i], 1, 7) == "Version")
  {
    rating <- as.numeric(substr(txt[i], nchar(txt[i]), nchar(txt[i])))
    ratings <- c(ratings, rating)
    
    # Get ratings for version.release.modifications
    ver.split <- unlist(strsplit(txt[i], " "))
    ver.rel.mod <- ver.split[2]
    temp.row <- list(Version=ver.rel.mod, Rating=rating, Count=1)
    
    ver.rel.mod.ratings[k, ] <- temp.row
    k <- k + 1
  }
  else
  {
    words <- c(words, txt[i])
    # words <- paste(words, txt[i], sep=" ")
  }
}

# subset data frame to get rid of empty rows (since it was prepopulated)
ver.rel.mod.ratings <- ver.rel.mod.ratings[ver.rel.mod.ratings$Rating != 0, ]

# used this reference
# https://sites.google.com/site/miningtwitter/questions/sentiment/sentiment

# clean up documents
# remove punctuation
words = gsub("[[:punct:]]", "", words)

# remove numbers
words = gsub("[[:digit:]]", "", words)

# remove unnecessary spaces
words = gsub("[ \t]{2,}", "", words)
words = gsub("^\\s+|\\s+$", "", words)

# define "tolower error handling" function 
try.error = function(x)
{
  # create missing value
  y = NA
  # tryCatch error
  try_error = tryCatch(tolower(x), error=function(e) e)
  # if not an error
  if (!inherits(try_error, "error"))
    y = tolower(x)
  # result
  return(y)
}
# lower case using try.error with sapply 
words = sapply(words, try.error)

# remove NAs in some_words
words = words[!is.na(words)]
names(words) = NULL

# classify polarity
class_pol = classify_polarity(words, algorithm="bayes")
# get polarity best fit
polarity = class_pol[,4]

# data frame with results
sent_df = data.frame(text=words, polarity=polarity, stringsAsFactors=FALSE)

# sort data frame
sent_df = within(sent_df,
                 polarity <- factor(polarity, levels=names(sort(table(polarity), decreasing=TRUE))))


# separating text by emotion
pols = levels(factor(sent_df$polarity))
npols = length(pols)
pol.docs = rep("", npols)
for (i in 1:npols)
{
  tmp = words[polarity == pols[i]]
  pol.docs[i] = paste(tmp, collapse=" ")
}

# remove stopwords
pol.docs = removeWords(pol.docs, stopwords("english"))

# create corpus
corpus = Corpus(VectorSource(pol.docs))
tdm = TermDocumentMatrix(corpus)
tdm = as.matrix(tdm)
colnames(tdm) = pols

# comparison word cloud
comparison.cloud(tdm, colors = brewer.pal(npols, "Dark2"),
                 scale = c(3,.5), random.order = FALSE, title.size = 1.5)

# write total run time to log
print(proc.time() - st)
