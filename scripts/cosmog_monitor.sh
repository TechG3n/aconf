#!/system/bin/sh
# version 4.0.1
#set -x

# Monitor by Oldmole && bbdoc

logfile="/sdcard/cosmog_monitor.log"
aconf="/data/local/tmp/cos/cosmog.toml"
origin=$(cat $aconf | tr , '\n' | grep -w 'device_Name' | awk -F "\"" '{ print $4 }')
android_version=`getprop ro.build.version.release | sed -e 's/\..*//'`
cosmogdead=0
pogodead=0
deviceonline="0"
emptycheck=9
updatecheck=0
healthchecklock=0
stalllock=0

source /data/local/aconf_versions
export useMonitor
export monitor_interval
export discord_webhook
export update_check_interval
export debug
update_check=$((update_check_interval/monitor_interval))

#Create logfile, stolen from cosmog.sh
if [ ! -e /sdcard/cosmog_monitor.log ] ;then
	touch /sdcard/cosmog_monitor.log
fi

# stderr to logfile
exec 2>> $logfile

check_for_updates() {
	[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Checking for updates" >> $logfile
	/system/bin/cosmog.sh -ua
}

stop_start_cosmog () {
	pkill -9 -f 'com\.nianticlabs\.pokemongo'
	sleep 5
	[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Running the start mapping service of cosmog" >> $logfile

	cd /data/local/tmp/cos && setsid nohup ./com.nianticlabs.pokemongo >/dev/null 2>&1 &

	sleep 1
}


send_webhook () {
	issue=$1;
	action=$2;
	curl -k -X POST $atvdetails_receiver_host:$atvdetails_receiver_port/webhook -H "Accept: application/json" -H "Content-Type: application/json" --data-binary @- <<DATA
        {
            "WHType": "ATVMonitor",
            "deviceName": "${origin}",
            "issue": "${issue}",
            "action": "${action}",
            "script": "cosmog_monitor.sh"
        }
DATA
}


echo "`date +%Y-%m-%d_%T` [MONITORBOT] Starting cosmog data monitor in 5 mins, loop is $monitor_interval seconds" >> $logfile
sleep 300
while :
do
	[[ $useMonitor == "false" ]] && echo "`date +%Y-%m-%d_%T` cosmog_monitor stopped" >> $logfile && exit 1

	until ping -c1 8.8.8.8 >/dev/null 2>/dev/null
	do
		[[ $( awk '/./{line=$0} END{print line}' $logfile | grep 'No internet' | wc -l) != 1 ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] No internet, pay the bill?" >> $logfile
		sleep 60
	done

		
	cosmog_check=$(pgrep -fl -f 'com\.nianticlabs\.pokemongo')
	if [[ -z $cosmog_check ]] && [[ -f /data/local/tmp/cos/config.toml ]] ;then
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] cosmog not running, starting it" >> $logfile
		pkill -9 -f 'com\.nianticlabs\.pokemongo' && cd /data/local/tmp/cos && setsid nohup ./com.nianticlabs.pokemongo >/dev/null 2>&1 &
	fi
	
	sleep $monitor_interval
done