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
rm -rf ./pastaminer_worker
echo "Remove complete !"
echo "See you soon, bye."
echo
}

function _remove_worker () {
rm -rf ./pastaminer_worker
echo "Worker removed !"
_main_menu
}

function _main_menu () {
echo
echo "1) Configure PastaMiner (easy/advanced)"
echo "2) Manage PastaMiner workers (start/stop/state)"
echo "3) Uninstall PastaMiner binaries and workers (could be reinstalled in 1mn)"
echo "4) Enable Plex streams watcher"
echo
echo "0) Exit."
echo
read -p "What do you want do ? " choice
case "$choice" in
	1 ) echo;ask_configure_easy;;
	2 ) _remove_worker;;
	3 ) _remove_pastaminer;;
	4 ) echo "Uninstall PastaMiner !";;
	0 ) echo "See you next time !";exit;;
esac
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

function _ask_create_worker () {
echo "I have everything I need to create your first worker !"
echo "Monero Wallet : $monero_wallet"
echo "Threads allocated : $nbthreads"
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
	#sed -i 's/      { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$j' },/      { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$j' },\n      { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$i' },/' ./pastaminer_worker/config.txt
done
echo "[DEBUG] Loop ended."
#read a #TEST

sed -i 's/ { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$nb_cpu_stop' },/ { "low_power_mode" : false, "no_prefetch" : false, "affine_to_cpu" : '$nb_cpu_stop' },\n\],/' ./pastaminer_worker/config.txt

sed -i '/"pool_address" : "pool.usxmrpool.com:3333"/c\"pool_address" : "pool.minexmr.com:7777",' ./pastaminer_worker/config.txt
sed -i '/"wallet_address" : "",/c\"wallet_address" : "'"$monero_wallet"'",' ./pastaminer_worker/config.txt
sed -i '/"pool_password" : "",/c\"pool_password" : "x",' ./pastaminer_worker/config.txt
echo "Done !"
}

function ask_configure_easy () {
echo "To configure XMR Stak CPU easily, you NEED few things :"
echo "1. Monero Wallet -to be paid- : you -could- create a cloud one here https://mymonero.com"
echo "2. Number of threads that you want to allocate to your worker"
echo "That's all ! -the default miner pool is http://minexmr.com-"
echo
_ask_wallet
_ask_nb_threads
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
