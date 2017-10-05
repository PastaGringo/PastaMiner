#!/bin/bash
nb_cpu_to_allocate=3
nb_cpu_start=0
nb_cpu_stop=$(($nb_cpu_start+$nb_cpu_to_allocate-1))

sed -i '/* "cpu_threads_conf" :/d' ./config.txt #remove line
sed -i '/* \[/d' ./config.txt #remove line
sed -i '/* \],/d' ./config.txt #remove line
sed -i '/ * { "low_power_mode" : false, "no_prefetch" : true, "affine_to_cpu" : 0 },/d' ./config.txt
sed -i '/ * { "low_power_mode" : false, "no_prefetch" : true, "affine_to_cpu" : 1 },/d' ./config.txt
sed -i '/"cpu_threads_conf" :/{n;d}' ./config.txt #remove line : null,

sed -i '/"cpu_threads_conf" :/a [' ./config.txt
sed -i 's/\[/\[\n      { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$nb_cpu_start' },/' config.txt
echo "done."

for i in $(seq $nbstart $nb_cpu_stop)
do
	if [ "$i" -eq "0" ]; then
		j=0
	else
		j=$(($i-1))
	fi
	echo "check $j and replace by $i"
	#sed -i 's/\[/\[\n { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$nb_cpu_start' },/' config.txt
	#echo "{ "low_power_mode" : false, "no_prefetch" : true, "affine_to_cpu" : $i },"
	sed -i 's/      { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$j' },/      { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$j' },\n      { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$i' },/' config.txt
done

sed -i 's/ { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : 2 },/ { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$nb_cpu_stop' },\n\],/' config.txt

echo "done."
