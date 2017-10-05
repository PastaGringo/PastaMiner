echo "Copying XMR Stak CPU..."
mkdir -p pastaminer_worker
cp xmr-stak-cpu/bin/* pastaminer_worker
echo "Done!"
echo "Configuring config.txt file..."
nb_cpu_to_allocate=$1
nb_cpu_start=0
nb_cpu_stop=$(($nb_cpu_start+$nb_cpu_to_allocate-1))
sed -i '/* "cpu_threads_conf" :/d' ./pastaminer_worker/config.txt #remove line
sed -i '/* \[/d' ./pastaminer_worker/config.txt #remove line
sed -i '/* \],/d' ./pastaminer_worker/config.txt #remove line
sed -i '/ * { "low_power_mode" : false, "no_prefetch" : true, "affine_to_cpu" : 0 },/d' ./pastaminer_worker/config.txt
sed -i '/ * { "low_power_mode" : false, "no_prefetch" : true, "affine_to_cpu" : 1 },/d' ./pastaminer_worker/config.txt
sed -i '/"cpu_threads_conf" :/{n;d}' ./pastaminer_worker/config.txt #remove line : null,
sed -i '/"cpu_threads_conf" :/a [' ./pastaminer_worker/config.txt
sed -i 's/\[/\[\n      { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$nb_cpu_start' },/' ./pastaminer_worker/config.txt
echo "done."
echo "[DEBUG] Beginning loop..."
#read a #TEST
for i in $(seq $nb_cpu_start $nb_cpu_stop)
do
        if [ "$i" -eq "0" ]; then
                j=0
        else
                j=$(($i-1))
        fi
        echo "check $j and replace by $i"
        #sed -i 's/\[/\[\n { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$nb_cpu_start' },/' config.txt
        #echo "{ "low_power_mode" : false, "no_prefetch" : true, "affine_to_cpu" : $i },"
        echo "REPLACE LINE $i"
        #sed -i 's/      { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$j' },/      { "low_power_mode" : false, "no_prefetch" : false, "affine_to_$
done
echo "[DEBUG] Loop ended."
#read a #TEST
                                                                                                                                                                           
sed -i 's/ { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$nb_cpu_stop' },/ { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$$
                                                                                                                                                                           
sed -i '/"pool_address" : "pool.usxmrpool.com:3333"/c\"pool_address" : "pool.minexmr.com:7777",' ./pastaminer_worker/config.txt
sed -i '/"wallet_address" : "",/c\"wallet_address" : "'"$monero_wallet"'",' ./pastaminer_worker/config.txt
sed -i '/"pool_password" : "",/c\"pool_password" : "x",' ./pastaminer_worker/config.txt
echo "Done !"
