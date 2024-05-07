#!/system/bin/sh
# version 3.4.2
#set -x

# Monitor by Oldmole && bbdoc

logfile="/sdcard/cosmog_monitor.log"
aconf="/data/local/tmp/cosmog.json"
origin=$(cat $aconf | tr , '\n' | grep -w 'deviceName' | awk -F "\"" '{ print $4 }')
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
	am force-stop com.nianticlabs.pokemongo &  rm -rf /data/data/com.nianticlabs.pokemongo/cache/* 2>/dev/null & am force-stop com.sy1vi3.cosmog 
	sleep 5
	[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Running the start mapping service of cosmog" >> $logfile

	am start -n com.sy1vi3.cosmog/com.sy1vi3.cosmog.MainActivity
	
	sleep 1
}

stop_pogo () {
	am force-stop com.nianticlabs.pokemongo & rm -rf /data/data/com.nianticlabs.pokemongo/cache/* 2>/dev/null
	sleep 5
	[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Killing pogo and clearing junk" >> $logfile
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

	[[ -z $origin ]] && origin=$(cat $aconf | tr , '\n' | grep -w 'deviceName' | awk -F "\"" '{ print $4 }')

        updatecheck=$(($updatecheck+1))
        if [[ $updatecheck -gt $update_check ]] ;then
		echo  "`date +%Y-%m-%d_%T` [MONITORBOT] Checking cosmog and Pogo for update" >> $logfile
		updatecheck=0
		check_for_updates
	fi

	if [ -d /data/data/com.sy1vi3.cosmog ] && [ -s /data/local/tmp/cosmog.json ]
	then
		[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] cosmog.json looks good" >> $logfile
	else
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] cosmog.json does not exist or is empty! Let's fix that" >> $logfile
		[[ ! -z $discord_webhook ]] && [[ $recreate_cosmog_config != "false" ]] && curl -S -k -L --fail --show-error -F "payload_json={\"content\": \"__**$origin**__: re-creating cosmog config\"}" $discord_webhook &>/dev/null
		/system/bin/cosmog.sh -ic
		[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Fixed config" >> $logfile
		stop_start_cosmog
		sleep $monitor_interval
		continue

	fi
		
	cosmog_check=$(ps -e | grep com.sy1vi3.cosmog | awk '{print $9}')
	if [[ -z $cosmog_check ]] && [[ -f /data/local/tmp/cosmog.json ]] ;then
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] cosmog not running, starting it" >> $logfile
		am start -n com.sy1vi3.cosmog/com.sy1vi3.cosmog.MainActivity
	fi
	
	sleep $monitor_interval
done