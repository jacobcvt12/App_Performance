#!/usr/local/bin/bash
# Store startng time in T
T=$(date +%s)

# contingency for database
if [ -a data/reviews.db ]
then
    sqlite3 data/reviews.db "CREATE TABLE IF NOT EXISTS Ratings 
        (company TEXT, version TEXT, rating INTEGER, review_date TEXT);"
    sqlite3 data/reviews.db "DELETE FROM Ratings;"
else
    echo "Must create sqlite database reviews.db"
    exit
fi

# Create associative array of hotels and OTAs
declare -A hotelIDs=(
[marriott]=455004730
[hilton]=337937175
[starwood]=312306003
[booking]=367003839
[expedia]=427916203
[kayak]=305204535
[airbnb]=401626263)

main_hotel=marriott

# Store current directory in DIR variable to pass to R
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# loop through all hotels and run python download script
for app in ${!hotelIDs[*]}
do
    # Call python script on hotel to download app reviews to hotel.reviews
    ./bin/download_app_reviews.py ${hotelIDs[$app]} > output/reviews/${app}.reviews &
    pidlist="$pidlist $!"
done

for job in $pidlist
do
    wait $job
done

# once downloads are done, perform individual app analysis with R 
# and upload to databas
for app in ${!hotelIDs[*]}
do
    # Call R program on dowloaded reviews. Write to hotel.log
    Rscript bin/review_analysis.R ${app} ${DIR} > output/logs/${app}.log 

    # grep through reviews to remove reviews
    # upload ratings to reviews.db
    grep -i "^version" output/reviews/${app}.reviews | cat | while read ignore version date rating; do
        sqlite3 data/reviews.db "INSERT INTO Ratings VALUES ('$app', '$version', $rating, '$date');"
    done
done

# run queries and update tables in database
sqlite3 data/reviews.db < bin/update_tables.sql

# pass main app and all other apps to R to run comparison
Rscript bin/app_performance_by_time.R ${DIR} ${main_hotel} ${!hotelIDs[*]}

# plot weekly report of main_hotel
Rscript bin/weekly_report.R ${DIR} ${main_hotel}

# Store ending time in T_e
T_e=$(date +%s)

# Total time in TT
TT=$((T_e - T))

printf "Time to run %02d:%02d\n" $((TT/60%60)) $((TT%60))
