suppressPackageStartupMessages(library(RSQLite))
suppressPackageStartupMessages(library(scales))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(plyr))

# handle arguments of parent directory [1] main app [2]
# and all other apps [3] (which repeatse main app and
# must be removed

args <- commandArgs(TRUE)
main_company <- args[2]
other_companies <- args[3:length(args)]

# remove main_company from other_companies
other_companies <- other_companies[other_companies != main_company]

# path to database
db <- paste(args[1], "/data/reviews.db", sep="")

# connect to database and pull ratings table
conn <- dbConnect("SQLite", db)
weekly_ratings_df <- dbGetQuery(conn, "SELECT * FROM ratings_by_week;")
weekly_ratings_df$week_end <- as.Date(weekly_ratings_df$week_end, "%Y-%m-%d")

# disconnect from database
# store in variable so as to avoid printing output
msg <- dbDisconnect(conn)

# set theme to apply to all plots
gg_theme = theme(panel.background = element_rect(fill='white', colour='black'))
for (app_company in other_companies)
{
  company.plots <- paste(args[1], sprintf("/figs/%s comparison_over_time.pdf", app_company), sep="")
  both_start_dt <- min(min(subset(weekly_ratings_df, company==app_company)$week_end),
                       min(subset(weekly_ratings_df, company==main_company)$week_end))
  wr_df_subset = subset(weekly_ratings_df, company %in% c(main_company, app_company))
  date_df_subset <- subset(wr_df_subset, week_end >= both_start_dt)
  date_df_subset$review_avg <- with(date_df_subset, ifelse(company!=main_company, -review_avg, review_avg))
  date_df_subset$review_count <- with(date_df_subset, ifelse(company!=app_company, -review_count, review_count))
  date_df_agg <- ddply(date_df_subset, .(week_end), summarize, rating_diff = sum(review_avg), review_diff = sum(review_count))
  
  review_avg_diff <- ggplot(date_df_agg, aes(week_end, rating_diff)) + 
    geom_line() + 
    scale_x_date(labels=date_format("%b %y")) + 
    ylab("Difference in Weekly Rating Average") + 
    xlab("Week Ending") +
    ggtitle(sprintf("Weekly Ratings\n%s vs %s", main_company, app_company)) + 
    gg_theme
  
  review_count_diff <- ggplot(date_df_agg, aes(week_end, review_diff)) + 
    geom_line() + 
    scale_x_date(labels=date_format("%b %y")) + 
    ylab("Difference in Weekly Review Counts") + 
    xlab("Week Ending") +
    ggtitle(sprintf("Weekly Reviews\n%s vs %s", main_company, app_company)) + 
    gg_theme
  
  compare_two <- ggplot(wr_df_subset, aes(week_end, review_avg, group=company, colour=company)) + 
    geom_line() + 
    scale_x_date(labels=date_format("%b %y")) + 
    xlab("Week Ending") +
    ylab("Average Rating") + 
    ggtitle(sprintf("Comparison of %s and %s over time", main_company, app_company)) + 
    gg_theme
  
  pdf(company.plots)
  print(review_avg_diff)
  print(review_count_diff)
  print(compare_two)
  dev.off()
}
