#!/bin/bash

declare -A animals

animals=(
[cow]=moo 
[fox]=kekeke)

for animal in ${!animals[*]};
do
	echo ${animals[$animal]};
done


file=$(mktemp)
progress() {
  pc=0;
  while [ -e $file ]
    do
      echo -ne "$pc sec\033[0K\r"
      sleep 1
      ((pc++))
    done
}
progress &
sleep 15

#now when everything is done
rm -f $file
