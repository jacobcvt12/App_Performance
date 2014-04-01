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

# delete previous output
rm -f output/logs/*
rm -f output/reviews/*
rm -f figs/*

# Create associative array of hotels and OTAs
declare -A hotelIDs=(
[marriott]=455004730
[hilton]=337937175
[starwood]=312306003
[ihg]=368217298
[booking]=367003839
[expedia]=427916203
[kayak]=305204535
[airbnb]=401626263
[tripadvisor]=284876795)

app_num=${#hotelIDs[@]}
export finished=0

# Store current directory in DIR variable to pass to R
DIR="$PWD"

# write header to summarized.reviews
echo "company,version,date,easy,slow,error,broken,crash,reviews" > ./output/reviews/summarized.reviews

# loop through all hotels and run python download script
for app in ${!hotelIDs[*]}
do
    echo "Downloading ${app}..."
    # Call python script on hotel to download app reviews to hotel.reviews and then
    # run analysis on downloaded reviews. 
    # remove parallelization of downloading to see if this fixes download erros
    ./bin/download_app_reviews.py ${hotelIDs[$app]} > output/reviews/${app}.reviews 2> output/logs/${app}_download.log
        echo "Running analysis on ${app}..." &&
        Rscript bin/review_analysis.R ${app} ${DIR} &> output/logs/${app}.log &&
        echo "Summarizing ${app} reviews..." &&
        cat ./output/reviews/${app}.reviews | ./bin/summarize_reviews.py ${app} >> ./output/reviews/summarized.reviews &&
        (( finished += 1 )) &&
        export finished &&
        echo "Finished running ${app}" &
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
    # grep through reviews to remove reviews
    # remove first column (text containing string "Version")
    # prepend company to text
    # replace space with pipe (sqlite3 separator)
    # upload ratings to reviews.db

    echo "Uploading ${app}..."
    grep "^Version.*[1-5]$" output/reviews/${app}.reviews | cut -d" " -f2- | 
        awk -v r=$app '{print r " " $0}' | sed 's/ /|/g' | 
        sqlite3 data/reviews.db '.import "/dev/stdin" Ratings'
done

echo "Running queries..."
# run queries and update tables in database
sqlite3 data/reviews.db < bin/update_tables.sql

echo "Writing aggregated results for tableau."
sqlite3 ./data/reviews.db < ./bin/output.sql | ./bin/tableau_output.py > ./output/tableau_tbl.txt

# copy pertinent output to windows
echo "Copying output to windows drive..."
DATE=`date -I`
WINDOW_PATH="/media/Ecom/Personal Folders/Jacob Carey/App_Performance_Output"
sudo mount -a &&
    cp ./output/reviews/summarized.reviews "$WINDOW_PATH" &&
    cp ./output/tableau_tbl.txt "$WINDOW_PATH" &&
    cp ./output/logs/* "$WINDOW_PATH" &&
    cp ./figs/*.pdf "$WINDOW_PATH" &&
    echo "Copied successfully..." ||
    echo "Unsuccessful copy..."

# Store ending time in T_e
T_e=$(date +%s)

# Total time in TT
TT=$((T_e - T))

printf "Time to run %02d:%02d\n" $((TT/60%60)) $((TT%60))
