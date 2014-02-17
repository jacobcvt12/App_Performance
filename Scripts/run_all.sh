# Store startng time in T
T=$(date +%s)

# contingency for database
if [ -a ../Reviews/reviews.db ]
then
    sqlite3 ../Reviews/reviews.db "CREATE TABLE IF NOT EXISTS Ratings 
        (company TEXT, version TEXT, rating INTEGER);"
    sqlite3 ../Reviews/reviews.db "DELETE FROM Ratings;"
else
    echo "Must create sqlite database reviews.db"
    exit
fi

# Create array of hotels and OTAs
HOTELS=(marriott hilton starwood booking expedia kayak airbnb)

# Store current directory in DIR variable to pass to R
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENTDIR="$(dirname "$dir")"

# loop through all hotels
for app in ${HOTELS[*]}
do
    # Call python script on hotel to download app reviews to hotel.reviews
    ./AppStoreScraper_domestic.py ${app} > ../Reviews/${app}.reviews

    # Call R program on dowloaded reviews. Write to hotel.log
    RScript AppStoreAnalysis.R ${app} ${PARENTDIR} > ../Logs/${app}.log 

    # grep through reviews to remove reviews
    # upload ratings to reviews.db
    grep -i "^version" ../Reviews/${app}.reviews | cat | while read ignore version rating; do
        sqlite3 ../Reviews/reviews.db "INSERT INTO Ratings VALUES ('$app', '$version', $rating);"
    done

done

# Store ending time in T_e
T_e=$(date +%s)

# Total time in TT
TT=$((T_e - T))

printf "Time to run %d:%d\n" $((TT/60%60)) $((TT%60))
