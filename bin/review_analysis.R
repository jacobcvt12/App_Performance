# Get system time to print total run time
st <- proc.time()
print("Running review_analysis.R")

# set options to print warnings as they appear
options(warn=1)

# import libraries
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(tm))
suppressPackageStartupMessages(library(wordcloud))
suppressPackageStartupMessages(library(plyr))
suppressPackageStartupMessages(library(scales))

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
words <- ""

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
    words <- paste(words, txt[i], sep=" ")
  }
}

# subset data frame to get rid of empty rows (since it was prepopulated)
ver.rel.mod.ratings <- ver.rel.mod.ratings[ver.rel.mod.ratings$Rating != 0, ]

# count words with regular expression (regex counts spaces and adds 1)
word.count <- sapply(gregexpr("\\W+", words), length) + 1

cat(sprintf("%s has %d reviews.\nThe reviews have %d words\n", 
              company, nrow(ver.rel.mod.ratings), word.count))

words <- tolower(words)

# remove some common words from the text
words <- gsub(company, "", words)
words <- gsub("app", "", words)

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
