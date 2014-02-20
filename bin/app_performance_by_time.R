library(RSQLite)
library(scales)
library(ggplot2)
db <- "~/marriott/App_Performance/data/reviews.db"

conn <- dbConnect("SQLite", db)
weekly_ratings_df <- dbGetQuery(conn, "SELECT * FROM ratings_by_week;")
weekly_ratings_df$week_end <- as.Date(weekly_ratings_df$week_end, "%Y-%m-%d")

wr_df_subset = subset(weekly_ratings_df, company %in% c("marriott", "hilton"))

p <- ggplot(wr_df_subset, aes(week_end, review_avg, group=company, colour=company)) + geom_line() + scale_x_date(labels=date_format("%b %y"))
print(p)
# marriott <- subset(weekly_ratings_df, company=="marriott")
# p <- ggplot(marriott, aes(week_end, review_avg)) + geom_line() + geom_smooth(method="lm") + scale_x_date(labels=date_format("%b %y"))
# q <- ggplot(marriott, aes(week_end, review_count)) + geom_line() + geom_smooth(method="lm") + scale_x_date(labels=date_format("%b %y"))
