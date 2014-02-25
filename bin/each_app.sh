# Call python script on hotel to download app reviews to hotel.reviews
./bin/download_app_reviews.py ${2} > output/reviews/${1}.reviews

# once download is done, perform individual app analysis with R 
# and upload to databas

# Call R program on dowloaded reviews. Write to hotel.log
Rscript bin/review_analysis.R ${1} ${3} > output/logs/${1}.log 

# grep through reviews to remove reviews
# upload ratings to reviews.db
grep -i "^version" output/reviews/${1}.reviews | cat | while read ignore version date rating; do
    sqlite3 data/reviews.db "INSERT INTO Ratings VALUES ('${1}', '$version', $rating, '$date');"
done
