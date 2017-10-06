#!/bin/bash
workers_array=()
#workers_array[0]="empty"
for worker in $(ls ../ | grep "pastaminer"); do
	#echo "Ajout de $worker au tableau"
	workers_array+=($worker)
	#echo "Ajouté"
done
echo "Tableau :"
for index in "${!workers_array[@]}"; do
	indexplus1=$(( $index+1 ))
	echo "$indexplus1) ${workers_array[index]}"
done
read -p "Which worker do you want to manage ?" workerchoice

indexminus1=$(($workerchoice-1))

if [ "$workerchoice" == "" ]; then
	echo "No value selected"
else
	echo "You choose ${workers_array[$indexminus1]}"
fi
