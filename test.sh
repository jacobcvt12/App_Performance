#!/bin/bash

declare -A animals

animals=(
[cow]=moo 
[fox]=kekeke)

for animal in ${!animals[*]};
do
	echo ${animals[$animal]};
done
