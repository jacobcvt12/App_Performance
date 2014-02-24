suppressPackageStartupMessages(library(RSQLite))
suppressPackageStartupMessages(library(scales))
suppressPackageStartupMessages(library(ggplot2))

# handle arguments of parent directory [1] main app [2]

args <- commandArgs(TRUE)
main_company <- args[2]

# path to database
db <- paste(args[1], "/data/reviews.db", sep="")

# connect to database and pull ratings table
conn <- dbConnect("SQLite", db)
last_week_df <- dbGetQuery(conn, "SELECT * FROM last_week;") 
last_week_df$review_date <- as.Date(last_week_df$review_date, "%Y-%m-%d") 
last_week_df <- subset(last_week_df, company == main_company) 

# disconnect from database
# store in variable so as to avoid printing output
msg <- dbDisconnect(conn)

company.plots <- paste(args[1], sprintf("/figs/%s weekly report.pdf", main_company), sep="")

last_week_reviews <- ggplot(last_week_df, aes(review_date, rating_avg)) + 
  geom_point(aes(shape=as.factor(rating_count))) + 
  scale_x_date(labels=date_format("%a")) + 
  ylab("Daily Rating Average") + 
  xlab("Day") +
  ggtitle("Daily Ratings") + 
  scale_shape_discrete(name="Review Count")

pdf(company.plots)
print(last_week_reviews)
dev.off()
