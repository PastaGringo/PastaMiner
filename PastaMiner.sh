#!/bin/bash
echo
#currentdir=$(pwd)
#echo $currentdir
#xmrstakcpudir=$currentdir/xmr-stak-cpu/
#echo $xmrstakcpudir
#echo $xmrstakcpudir

version="b0.004"

function _check_updates () {
echo
echo "Currenlty no checking function..."
echo "Downloading latest PastaMiner.sh version..."
rm ./PastaMiner.sh > /dev/null
wget https://raw.githubusercontent.com/PastaGringo/PastaMiner/master/PastaMiner.sh &> /dev/null
echo "OK."
echo "Starting latest version in few seconds..."
chmod +x ./PastaMiner.sh
countdown "00:00:05"
bash ./PastaMiner.sh
}

function countdown () {
IFS=:
set -- $*
secs=$(( ${1#0} * 3600 + ${2#0} * 60 + ${3#0} ))
while [ $secs -gt 0 ]
do
	sleep 1 &
	printf "\r%02d:%02d:%02d" $((secs/3600)) $(( (secs/60)%60)) $((secs%60))
	secs=$(( $secs - 1 ))
	wait
done
echo
}

function _check_plex_stream_watcher () {
if [ -f ./.flags/plex_stream_watcher ]; then
	echo
	echo "Plex Streams Watcher ENABLED !"
	echo
	countdown "00:00:05"
	_plex_streams_watcher stop
	_main_menu
else
	echo
	echo "Plex Streams Watcher DISABLED !"
	echo
	#_main_menu
fi
}

function _ask_plex_streams_watcher () {
#need plex token
echo
echo "Plex streams watch will suspend your workers if any Plex streams is detected."
echo "You should enable it if you shared your Plex server with users, because mining consume a lot of CPU."
echo "But for example, if ALL of your miners has 4 threads (max) dedicated and your CPU has 12cores, it should be fine."
echo "What Plex stream watcher will do :"
echo "> Check every X seconds if there are any streams :"
echo "- if YES : stop all miners running."
echo "- if NO : start all previous running miners."
echo
echo "1) Start Plex Stream Watcher"
echo "2) Stop Plex Stream Watcher"
echo "0) Main menu."
echo
read -p "Would you like to enable Plex Streams Watcher to all your miners ? " plex_stream_watcher_choice
case "$plex_stream_watcher_choice" in
	1 ) _plex_streams_watcher start;;
	2 ) _plex_streams_watcher stop;;
	0) _main_menu;;
	* ) echo WRONG;;
esac
}

function _plex_streams_watcher () {
echo
if [ "$1" == "start" ]; then
	echo "Staring Plex stream watcher..."
	touch ./.flags/plex_stream_watcher
	echo "Plex Stream Watcher is ENABLED !"
	_main_menu
elif [ "$1" == "stop" ]; then
	echo "Stopping Plex stream watcher..."
	rm ./.flags/plex_stream_watcher
	echo "Plex Stream Watcher is DISABLED !"
else
	echo "Invalid input for Plex Stream Watcher"
	_main_menu
fi
}

function _create_log_file () {
if [ ! -d .flags ]; then
	mkdir .flags
else
	#echo "[DEBUG] Dossier flags existant!"
	flags=ok
fi
}

function _check_xmr_stak_cpu_state () {
if [ -f ./.flags/downloaded ]; then
	#echo "[DEBUG] XMR Stak CPU downloaded !"
	downloaded=ok
else
	#echo "[DEBUG] XMR Stak CPU NOT downloaded !"
	downloaded=ko
fi
if [ -f ./.flags/built ]; then
	#echo "[DEBUG] XMR Stak CPU built !"
	built=ok
else
	#echo "[DEBUG] XMR Stak CPU NOT built !"
	#echo "[DEBUG] XMR Stak CPU not downloaded and built."
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

function _worker_status_from_main_menu () {
echo
if [[ $(screen -ls) == *"pastaminer"* ]]; then
	echo "Current active workers :"
	active_workers=$(screen -ls| grep "pastaminer")
	echo -e "\e[32m$active_workers\e[39m"
else
	echo "There is no active worker."
fi
echo
}

function _check_state () {
if [[ $(screen -ls) == *"$1"* ]]; then
	state=$(echo -e "\e[32mRUNNING\e[39m")
else
	state=$(echo -e "\e[31mNOT RUNNING\e[39m")
fi
#echo "$1 is $state"
}

function _worker_status_widget () {
workers=$(ls | grep "pastaminer")
if [ ! "$workers" == "" ]; then
	#echo "-------------------------------------------------------------------------------------------------------------------------------------------------------"
	echo "  Worker name		  Status	  Miner pool	  Wallet                                                                             "
	echo "-----------------------------------------------------------------------------------------------------------------------------------------------------------"
	for worker in $workers; do
	_check_state $worker
	echo "| $worker	| $state	|            	|                                                                                                 |"
	echo "-----------------------------------------------------------------------------------------------------------------------------------------------------------"
	done
else
	echo "There is no active worker."
fi
echo
}

function _main_menu () {
clear
_show_ascii
#_worker_status_from_main_menu
_check_plex_stream_watcher
_worker_status_widget
echo "1) Configure PastaMiner (easy/advanced)"
echo "2) Manage PastaMiner workers (start/stop/state/delete)"
echo "3) Uninstall PastaMiner binaries and workers (could be reinstalled in 1mn)"
echo "4) Enable Plex streams watcher"
echo "5) Check updates (will overwrite local PastaMiner.sh with the latest available on git)"
echo "0) Exit."
echo
read -p "What do you want do ? " choice
case "$choice" in
	1 ) echo;ask_configure_easy;;
	2 ) echo;_ask_manage_worker;;
	3 ) _remove_pastaminer;;
	4 ) _ask_plex_streams_watcher;;
	5 ) _check_updates;;
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
	2 ) echo;_worker_stop $workerchoicename;;
	3 ) echo;_worker_status $workerchoicename;;
	4 ) echo;ask_worker_delete $workerchoicename;;
esac
}

function _worker_status () {
if [[ $(screen -ls) == *"$1"* ]]; then
	echo "Worker $1 is RUNNING"
else
	echo "Worker $1 is NOT RUNNING"
fi
_main_menu
}

function ask_worker_delete () {
read -p "Are you absolutely sure that you want delete $1 ? [y/n] " choice
case "$choice" in
	y|Y ) echo; _worker_delete $1;;
	n|N ) echo;echo "I don't do nothing.";;
	* ) echo WRONG;;
esac
}

function _worker_delete () {
echo HERE
_worker_stop $1
echo "Deleting worker $1"
rm -rf $1
echo "Worker $1 has been DELETED."
_main_menu
}

function _worker_start () {
worker_screen_list=$(screen -ls)
echo "Starting worker $workerchoicename..."
echo
cd $1
screen -dmS $1 ./xmr-stak-cpu
if [[ $(screen -ls) == *"$1"* ]]; then
	echo "$workerchoicename has been started !"
else
	echo "$workerchoicename has NOT been started !"
fi
_main_menu
}

function _worker_stop () {
if [[ $(screen -ls) == *"$1"* ]]; then
	echo "$1 has been found."
	echo "Killing it..."
	screen -X -S $1 kill
	if [[ ! $(screen -ls) == *"$1"* ]]; then
		echo "$1 has been stopped !"
		_main_menu
	else
		echo "[ERROR]I can't kill it... !"
		_main_menu
	fi
else
	echo "There is no ACTIVE worker called $1"
fi
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
#echo Welcome to PastaMiner.sh !
function _show_ascii () {
echo '							     __          _               _                  '
echo '							   / _ \__ _ ___| |_ __ _  /\/\ (_)_ __   ___ _ __  '
echo '							  / /_)/ _` / __| __/ _  |/    \| |  _ \ / _ \  __| '
echo '							 / ___/ (_| \__ \ || (_| / /\/\ \ | | | |  __/ |    '
echo '							 \/    \__,_|___/\__\__,_\/    \/_|_| |_|\___|_|    '
echo
echo "Current version : $version"
}

clear
_show_ascii
_create_log_file
_check_xmr_stak_cpu_state
#_ask_build_xmr_stak_cpu
_main_menu
#echo
#echo What do you want to do ?
echo
