#!/usr/local/bin/bash

#declare -A animals

<<<<<<< HEAD
animals=(
[cow]=moo 
[fox]=kekeke
[cat]=meow
[dog]=bark)
=======
#animals=(
#[cow]=moo 
#[fox]=kekeke)
>>>>>>> 9286bebfbf9faa4827e46c5e3eaf7f693ea9395c

#for animal in ${!animals[*]};
#do
	#echo ${animals[$animal]};
#done

echo ""
echo "${!animals[0]}"

<<<<<<< HEAD
#file=$(mktemp)
#progress() {
#  pc=0;
#  while [ -e $file ]
#    do
#      echo -ne "$pc sec\033[0K\r"
#      sleep 1
#      ((pc++))
#    done
#}
#progress &
#sleep 15
#
##now when everything is done
#rm -f $file
=======
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
>>>>>>> 9286bebfbf9faa4827e46c5e3eaf7f693ea9395c
