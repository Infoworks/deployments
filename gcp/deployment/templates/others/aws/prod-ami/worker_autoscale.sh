#!/bin/bash
inputfile="$1"
whileout="$2"
finalout="$3"
while read -r line
do
   name="$line"
   jo fqdn=$name	
sed '$!s/$/,/' $2 > $3
done < "$inputfile" > "$whileout" 
