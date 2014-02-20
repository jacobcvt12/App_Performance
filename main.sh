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

# create temp file so function will run
file=$(mktemp)

# timer function
timer() {
    pc=0;
    while [ -e $file ]
    do
        if [ "$pc" == "0" ]; then
            printf " User Time: 00:00:00\r"
        else
            printf " User Time: %02d:%02d:%02d\r" $((pc/3600)) $((pc/60%60)) $((pc % 60))
        fi

        sleep 1
        ((pc++))
    done
}

# start timer as background process
timer &

# Create associative array of hotels and OTAs
# to add or remove apps, simply edit this array
# HOTELS=(marriott hilton starwood booking expedia kayak airbnb)
declare -A hotelIDs=(
[marriott]=455004730
[hilton]=337937175
[starwood]=312306003
[booking]=367003839
[expedia]=427916203
[kayak]=305204535
[airbnb]=401626263)

# Store current directory in DIR variable to pass to R
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# loop through all hotels
for app in ${!hotelIDs[*]}
do
    # Call python script on hotel to download app reviews to hotel.reviews
    ./bin/download_app_reviews.py ${hotelIDs[$app]} > output/reviews/${app}.reviews

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

# will need to run R with updated database

# Store ending time in T_e
T_e=$(date +%s)

# Total time in TT
TT=$((T_e - T))

# get rid of timer by deleting temp file
rm -f $file

printf "Time to run %d:%d\n" $((TT/60%60)) $((TT%60))
