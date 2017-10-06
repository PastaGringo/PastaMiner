#!/bin/bash
clear
echo
#currentdir=$(pwd)
#echo $currentdir
#xmrstakcpudir=$currentdir/xmr-stak-cpu/
#echo $xmrstakcpudir
#echo $xmrstakcpudir

function _create_log_file () {
if [ ! -d .flags ]; then
	mkdir .flags
else
	echo "[DEBUG] Dossier flags existant!"
fi
}

function _check_xmr_stak_cpu_state () {
if [ -f ./.flags/downloaded ]; then
	echo "[DEBUG] XMR Stak CPU downloaded !"
else
	echo "[DEBUG] XMR Stak CPU NOT downloaded !"
fi
if [ -f ./.flags/built ]; then
	echo "[DEBUG] XMR Stak CPU built !"
else
	echo "[DEBUG] XMR Stak CPU NOT built !"
	echo "[DEBUG] XMR Stak CPU not downloaded and built."
	_ask_xmr_stak_cpu
fi
}

function _build_xmr_stak_cpu () {
if [ ! -d ./.pastaminer/built ]; then
	echo "Installing dependencies..."
	sudo apt-get install libmicrohttpd-dev libssl-dev cmake build-essential libhwloc-dev -y > /dev/null
	echo "Dependencies installed !"
	echo
	echo "Building XMR Stak CPU..."
	cd xmr-stak-cpu
	cmake .
	make install
	cd ..
	if [ -f xmr-stak-cpu/bin/xmr-stak-cpu ]; then
		echo
		echo "XMR Stak CPU built !"
		echo
		touch ./.flags/built
		clear
	else
		echo "[ERROR] Something went wrong during the built !"
		echo "Bye."
		exit
	fi
else
	echo "XMR Stak CPU already built !"
fi
echo
echo "Everything is OK, let's mine some coins now !"
}

function _ask_build_xmr_stak_cpu () {
echo
read -p "Would you like to built it now ? [y/n] " choice
case "$choice" in
	y|Y ) _build_xmr_stak_cpu;;
	n|N ) echo;echo "Bye!";;
	* ) echo WRONG;;
esac
}

function _remove_pastaminer () {
rm -rf ./xmr-stak-cpu
rm -rf .flags
rm -rf ./pastaminer-*
echo "Remove complete !"
echo "See you soon, bye."
echo
}

function _remove_worker () {
echo "NEED UPDATE"
exit
rm -rf ./pastaminer
echo "Worker removed !"
_main_menu
}

function _main_menu () {
echo
echo "1) Configure PastaMiner (easy/advanced)"
echo "2) Manage PastaMiner workers (start/stop/state/delete)"
echo "3) Uninstall PastaMiner binaries and workers (could be reinstalled in 1mn)"
echo "4) Enable Plex streams watcher"
echo
echo "0) Exit."
echo
read -p "What do you want do ? " choice
case "$choice" in
	1 ) echo;ask_configure_easy;;
	2 ) echo;_ask_manage_worker;;
	3 ) _remove_pastaminer;;
	4 ) echo "Uninstall PastaMiner !";;
	0 ) echo "See you next time !";exit;;
esac
}

function _ask_manage_worker () {
workers_array=()
workers=$(ls | grep "pastaminer")

if [ "$workers" == "" ]; then
	echo "You don't have any worker, let's create one !"
	echo;ask_configure_easy
fi

for worker in $workers; do
	#echo "Ajout de $worker au tableau"
	workers_array+=($worker)
	#echo "Ajouté"
done
echo "List of your workers :"
for index in "${!workers_array[@]}"; do
	indexplus1=$(( $index+1 ))
	echo "$indexplus1) ${workers_array[index]}"
done
echo
read -p "Which worker do you want to manage ?" workerchoice

indexminus1=$(($workerchoice-1))

if [ "$workerchoice" == "" ]; then
	echo "No value selected"
else
	echo "You choose ${workers_array[$indexminus1]}"
	workerchoicename="${workers_array[$indexminus1]}"
	_ask_worker_action
fi
}

function _ask_worker_action () {
echo
echo "1) Start worker"
echo "2) Stop worker"
echo "3) Status worker"
echo "4) Delete worker"
echo
read -p "What do you want to do for $workerchoicename ?" workeraction
_worker_action
}

function _worker_action () {
case "$workeraction" in
	1 ) echo;_worker_start $workerchoicename;;
	2 ) echo "Stopping it !";;
	3 ) echo "Status";;
	4 ) echo "Deleting it !";;
esac
}

function _worker_start (){
worker_screen_list=$(screen -ls)
echo "Starting worker $workerchoicename..."
echo
cd $workerchoicename
screen -dmS $workerchoicename ./xmr-stak-cpu
if [[ $(screen -ls) == *"$workerchoicename"* ]]; then
	echo "$workerchoicename has been started !"
else
	echo "$workerchoicename has NOT been started !"
fi
_main_menu
}

function _ask_wallet () {
read -p "Could you give me your Monero account Wallet please ? " monero_wallet
echo "Got it."
echo
}

function _ask_nb_threads () {
nbproc=$(nproc)
echo "You currently have $nbproc CPU that can be dedicated to your workers"
echo
echo "BE CAREFUL, surallocating threads is dangerous for your system !"
echo "=> DO NOT exceed $nbproc (PastaMiner will not permit it)"
echo "=> For safety, allocate $nbproc-1 threads to let your system breath a bit :)"
echo
read -p "How many threads do you want to allocte to your worker ? " nbthreads
echo "Ok, $nbthreads seems good !"
echo
}

function _ask_worker_name () {
UUID=$RANDOM
read -p "How do you want to name your worker ? (if not pastaminer-$UUID will be used)" worker_name
if [ "$worker_name" == "" ]; then
	worker_name="pastaminer-$UUID"
	echo "So let's use $worker_name"
else
	echo "What a beautiful name ! "
fi
}

function _ask_create_worker () {
echo "I have everything I need to create your first worker !"
echo "Monero Wallet : $monero_wallet"
echo "Threads allocated : $nbthreads"
echo "Worker name : $worker_name"
echo
read -p "Would you like to create it now ? [y/n] " confirmation
case "$confirmation" in
	y|Y ) _create_worker $nbthreads;;
	n|N ) echo "Oh.";;
	* ) echo "INVALID ANSWER";;
esac
}

function _create_worker () {
echo "Copying XMR Stak CPU..."
mkdir -p $worker_name
cp xmr-stak-cpu/bin/* $worker_name
echo "Done!"
echo
echo "Configuring config.txt file..."
nb_cpu_to_allocate=$1
nb_cpu_start=0
nb_cpu_stop=$(($nb_cpu_start+$nb_cpu_to_allocate-2))
echo "CPU STOP : " $nb_cpu_stop
sed -i '/* "cpu_threads_conf" :/d' ./$worker_name/config.txt #remove line
sed -i '/* \[/d' ./$worker_name/config.txt #remove line
sed -i '/* \],/d' ./$worker_name/config.txt #remove line
sed -i '/ * { "low_power_mode" : false, "no_prefetch" : true, "affine_to_cpu" : 0 },/d' ./$worker_name/config.txt
sed -i '/ * { "low_power_mode" : false, "no_prefetch" : true, "affine_to_cpu" : 1 },/d' ./$worker_name/config.txt
sed -i '/"cpu_threads_conf" :/{n;d}' ./$worker_name/config.txt #remove line : null,
sed -i '/"cpu_threads_conf" :/a [' ./$worker_name/config.txt
sed -i 's/\[/\[\n      { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$nb_cpu_start' },/' ./$worker_name/config.txt
#echo "[DEBUG] Beginning loop..."
#read a #TEST
for i in $(seq $nb_cpu_start $nb_cpu_stop)
do
	#if [ "$i" -eq "0" ]; then
	#	j=0
	#else
	#	j=$(($i-1))
	#fi
	j=$(($i+1))
	#echo "check $i and replace by $j"
	sed -i 's/      { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$i' },/      { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$i' },\n      { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$j' },/' ./$worker_name/config.txt
done
#echo "[DEBUG] Loop ended."
#read a #TEST

sed -i 's/      { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$j' },/      { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$j' },\n\],/' ./$worker_name/config.txt

sed -i '/"pool_address" : "pool.usxmrpool.com:3333"/c\"pool_address" : "pool.minexmr.com:7777",' ./$worker_name/config.txt
sed -i '/"wallet_address" : "",/c\"wallet_address" : "'"$monero_wallet"'",' ./$worker_name/config.txt
sed -i '/"pool_password" : "",/c\"pool_password" : "x",' ./$worker_name/config.txt
echo "Done !"
echo
echo "Your worker $worker_name is ready to mine !"
echo "Return the main menu to start it !"
echo
_main_menu
}

function ask_configure_easy () {
echo "To configure XMR Stak CPU easily, you NEED few things :"
echo "1. Monero Wallet -to be paid- : you -could- create a cloud one here https://mymonero.com"
echo "2. Number of threads that you want to allocate to your worker"
echo "That's all ! -the default miner pool is http://minexmr.com-"
echo
_ask_wallet
_ask_nb_threads
_ask_worker_name
_ask_create_worker
}

function _ask_xmr_stak_cpu () {
echo
echo "You can't use PastaMiner.sh without XMR Stak CPU."
echo
read -p "Do you want to download it ? (y/n) " choice
case "$choice" in
	y|Y ) echo;_install_xmr_stak_cpu;;
	n|N ) echo;echo "Bye!";;
	* ) echo;_check_xmr_stak_cpu;;
esac
}

function _install_xmr_stak_cpu () {
echo "Downloading XMR Stak CPU..."
git clone --quiet https://github.com/fireice-uk/xmr-stak-cpu.git
if [ -d xmr-stak-cpu ]; then
	echo "XMR Stak CPU downloaded !"
	touch .flags/downloaded
else
	echo "[ERROR] Something went wrong during the git command."
	echo "Bye."
	exit
fi
_ask_build_xmr_stak_cpu
}

function _uninstall_xmr-stak-cpu () {
echo Uninstalling
rm -rf xmr-stak-cpu
}

#MAIN MENU

echo Welcome to PastaMiner.sh !
echo
_create_log_file
_check_xmr_stak_cpu_state
#_ask_build_xmr_stak_cpu
_main_menu
#echo
#echo What do you want to do ?
echo
