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

# count words with regular expression (regex counts spaces and adds 1)
word.count <- sapply(gregexpr("\\W+", words), length) + 1

cat(sprintf("%s has %d reviews.\nThe reviews have %d words\n", 
              company, nrow(ver.rel.mod.ratings), word.count))

# words <- tolower(words)
# 
# # remove some common words from the text
# words <- gsub(company, "", words)
# words <- gsub("app", "", words)

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

# classify emotion
# class_emo = classify_emotion(words, algorithm="bayes", prior=1.0)
# get emotion best fit
# emotion = class_emo[,7]
# substitute NA's by "unknown"
# emotion[is.na(emotion)] = "unknown"

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


# plot ratings over time
# reverse ratings since ratings are read new to old
ratings.sort <- rev(ratings)
t <- 1:length(ratings)
df <- data.frame(x=t, y=ratings.sort)
p <- ggplot(df, aes(x=x, y=y)) + geom_point(colour="black", position="jitter") + 
  geom_smooth(method="lm", colour="blue") + 
  geom_hline(yintercept=mean(ratings), linetype="dashed") + 
  ylab(sprintf("App Store Rating for %s", company)) + 
  xlab("Time") + 
  theme(axis.text.x=element_blank()) + 
  ggtitle("App Store Reviews")

# plot box plot version ratings
# subset the data to only plot the top 12 
# (or all of the Versions whichever is smaller)
vsum <- ddply(ver.rel.mod.ratings, "Version",
              function(vdf) sum(vdf$Count))

top_n <- min(12, nrow(vsum))

if (top_n < 12)
{
  cat(sprintf("%s only had %d versions, so all versions are displayed\n",
                company, top_n))
}

# subset aggregated dataset, then join back to original data set
# to plot only the top 12 versions (or all versions if <= 12)
vsum.subset <- vsum[with(vsum, order(-V1)), ][1:top_n, ]
ver.merge <- merge(x=ver.rel.mod.ratings, y=vsum.subset, by="Version")

give.n <- function(x){
  return(c(y = mean(x), label = length(x)))
}

bp <- ggplot(ver.merge, aes(Version, Rating)) + 
  geom_boxplot(fill = "grey80", colour = "#3366FF") + 
  stat_summary(fun.data = give.n, geom = "text") +
  ggtitle(sprintf("Top %d of %s App Versions \n(By Count)", top_n, company))

sbp <- ggplot(ver.merge, aes(Version, fill=as.factor(Rating))) + 
  geom_bar() +
  ylab("Ratings") +
  ggtitle(sprintf("Stacked Bars of Version Reviews\n(Top %d By Count)", 
                  top_n)) +
  scale_fill_discrete(name="Rating")

sbp.pct <- ggplot(ver.merge, aes(Version, fill=as.factor(Rating))) + 
  geom_bar(position='fill') +
  ylab("Ratings") +
  ggtitle(sprintf("Stacked Bars of Version Reviews (Percentage)
                  (Top %d By Count)", top_n)) +
  scale_fill_discrete(name="Rating") +
  scale_y_continuous(labels=percent)

# write plots to pdf
pdf(company.plots)
print(p)
print(bp)
print(sbp)
print(sbp.pct)
suppressWarnings(wordcloud(words, min.freq=15))
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
