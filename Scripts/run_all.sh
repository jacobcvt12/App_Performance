# Store startng time in T
T=$(date +%s)

# Create array of hotels and OTAs
HOTELS=(marriott hilton starwood booking expedia kayak airbnb)

# Store current directory in DIR variable to pass to R
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENTDIR="$(dirname "$dir")"

for app in ${HOTELS[*]}
do
    ./AppStoreScraper_domestic.py ${app} > ../Reviews/${app}.reviews
    RScript AppStoreAnalysis.R ${app} ${PARENTDIR} > ../Logs/${app}.log 
done

# Store ending time in T_e
T_e=$(date +%s)

# Total time in TT
TT=$((T_e - T))

printf "Time to run %d:%d\n" $((TT/60%60)) $((TT%60))
