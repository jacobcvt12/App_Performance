library(ggplot2)
library(wordcloud)
library(plyr)
library(scales)

args <- commandArgs(TRUE)
company <- args[1]
review.data <- paste(args[2], "/../Reviews/", company, ".reviews", sep="")
company.plots <- paste(args[2], "/../Output/", company, ".output.pdf", sep="")
txt <- readLines(review.data)

ratings <- c()
version.ratings <- list(c(0, 0), c(0, 0), c(0, 0))
words <- ""
ver.rel.mod.ratings <- data.frame("Version"=character(1080), "Rating"=integer(1080), "Count"=integer(1080), stringsAsFactors=FALSE)
k <- 1

for (i in 1:length(txt))
{
  if (substr(txt[i], 1, 7) == "Version")
  {
    Version.Num <- as.numeric(substr(txt[i], 9, 9))
    rating <- as.numeric(substr(txt[i], nchar(txt[i]), nchar(txt[i])))
    version.ratings[[Version.Num]][1] <- version.ratings[[Version.Num]][1] + 
      rating
    version.ratings[[Version.Num]][2] <- version.ratings[[Version.Num]][2] + 1 
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

ver.rel.mod.ratings <- ver.rel.mod.ratings[ver.rel.mod.ratings$Rating != 0, ]

ver.avg <- list(0, 0, 0)

for (j in 1:3)
{
  ver.avg[[j]] <- version.ratings[[j]][1] / version.ratings[[j]][2]
}

words <- tolower(words)

words <- gsub(company, "", words)
words <- gsub("app", "", words)

# plot ratings over time
ratings.sort <- rev(ratings)
t <- 1:length(ratings)
df <- data.frame(x=t, y=ratings.sort)
p <- ggplot(df, aes(x=x, y=y)) + geom_point(colour="black", position="jitter") + 
  geom_smooth(method="lm", colour="blue") + 
  geom_hline(yintercept=mean(ratings), linetype="dashed") + 
#   geom_hline(yintercept=ver.avg[[1]], linetype="dotted") +
#   geom_hline(yintercept=ver.avg[[2]], linetype="dotted") +
#   geom_hline(yintercept=ver.avg[[3]], linetype="dotted") +
#   scale_y_continuous(breaks=sort(c(1:5, ver.avg[[1]], ver.avg[[1]], 
#                                    ver.avg[[3]]))) + 
  ylab("App Store Rating for Marriott International") + xlab("Time") + 
  theme(axis.text.x=element_blank()) + ggtitle("App Store Reviews")

# plot box plot version ratings
# subset the data to only plot the top 55%
vsum <- ddply(ver.rel.mod.ratings, "Version",
                         function(vdf) sum(vdf$Count))

vsum.subset <- 
  data.frame(Version=subset(vsum, V1 > quantile(vsum$V1)[["50%"]])[, "Version"])
ver.merge <- merge(x=ver.rel.mod.ratings, y=vsum.subset, by="Version")

give.n <- function(x){
  return(c(y = mean(x), label = length(x)))
}

bp <- ggplot(ver.merge, aes(Version, Rating)) + 
  geom_boxplot(fill = "grey80", colour = "#3366FF") + 
  stat_summary(fun.data = give.n, geom = "text") +
  ggtitle("Top 50% of Marriott App Versions \n(By Count)")

sbp <- ggplot(ver.merge, aes(Version, fill=as.factor(Rating))) + 
  geom_bar() +
  ylab("Ratings") +
  ggtitle("Stacked Bars of Version Reviews\n(Top 50% By Count)") +
  scale_fill_discrete(name="Rating")

sbp.pct <- ggplot(ver.merge, aes(Version, fill=as.factor(Rating))) + 
  geom_bar(position='fill') +
  ylab("Ratings") +
  ggtitle("Stacked Bars of Version Reviews (Percentage)\n(Top 50% By Count)") +
  scale_fill_discrete(name="Rating") +
  scale_y_continuous(labels=percent)

pdf(company.plots)
print(p)
print(bp)
print(sbp)
print(sbp.pct)
wordcloud(words, min.freq=15)
invisible(dev.off())
