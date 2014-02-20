#!/usr/local/bin/bash

#declare -A animals

#animals=(
#[cow]=moo 
#[fox]=kekeke)

#for animal in ${!animals[*]};
#do
	#echo ${animals[$animal]};
#done


file=$(mktemp)
progress() {
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
progress &
sleep 5

#now when everything is done
rm -f $file
