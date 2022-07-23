#!/system/bin/sh
# version 3.1.7

# Monitor by Oldmole && bbdoc

logfile="/sdcard/atlas_monitor.log"
aconf="/data/local/tmp/atlas_config.json"
origin=$(cat $aconf | tr , '\n' | grep -w 'deviceName' | awk -F "\"" '{ print $4 }')
atlasdead=0
pogodead=0
deviceonline="0"
emptycheck=9
updatecheck=0

source /data/local/aconf_versions
export useMonitor
export monitor_interval
export discord_webhook
export update_check_interval
export debug
update_check=$((update_check_interval/monitor_interval))

#Create logfile, stolen from atlas.sh
if [ ! -e /sdcard/atlas_monitor.log ] ;then
	touch /sdcard/atlas_monitor.log
fi

# stderr to logfile
exec 2>> $logfile

check_for_updates() {
	[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Checking for updates" >> $logfile
	/system/bin/atlas.sh -ua
}

stop_start_atlas () {
	am force-stop com.nianticlabs.pokemongo &  rm -rf /data/data/com.nianticlabs.pokemongo/cache/* & am force-stop com.pokemod.atlas 
	sleep 5
	[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Running the start mapping service of Atlas" >> $logfile
	am startservice com.pokemod.atlas/com.pokemod.atlas.services.MappingService
	sleep 1

}

stop_pogo () {
	am force-stop com.nianticlabs.pokemongo & rm -rf /data/data/com.nianticlabs.pokemongo/cache/*
	sleep 5
	[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Killing pogo and clearing junk" >> $logfile

}

echo "`date +%Y-%m-%d_%T` [MONITORBOT] Starting atlas data monitor in 5 mins, loop is $monitor_interval seconds" >> $logfile
sleep 300
while :
do
	[[ $useMonitor == "false" ]] && echo "`date +%Y-%m-%d_%T` atlas_monitor stopped" >> $logfile && exit 1

	until ping -c1 8.8.8.8 >/dev/null 2>/dev/null
	do
		[[ $( awk '/./{line=$0} END{print line}' $logfile | grep 'No internet' | wc -l) != 1 ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] No internet, pay the bill?" >> $logfile
		sleep 60
	done

        updatecheck=$(($updatecheck+1))
        if [[ $updatecheck -gt $update_check ]] ;then
		echo  "`date +%Y-%m-%d_%T` [MONITORBOT] Checking Atlas and Pogo for update" >> $logfile
		updatecheck=0
		check_for_updates
	fi

	if [ -d /data/data/com.pokemod.atlas ] && [ -s /data/local/tmp/atlas_config.json ]
		then
			[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] atlas_config.json looks good" >> $logfile
	else
			echo "`date +%Y-%m-%d_%T` [MONITORBOT] atlas_config.json does not exist or is empty! Let's fix that" >> $logfile
			[[ ! -z $discord_webhook ]] && [[ $recreate_atlas_config != "false" ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas monitor\", \"content\": \"__**$origin**__: re-creating atlas config\"}" $discord_webhook &>/dev/null
			/system/bin/atlas.sh -ic
			[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Fixed config" >> $logfile
			stop_start_atlas
			sleep $monitor_interval
			continue

	fi


	dumpsys activity services | grep -e "MappingService" > /dev/null 2>&1
	devicestatus=$(echo $?)
	emptycheck="9$devicestatus"

	not_licensed=$(tail -n 100 /data/local/tmp/atlas.log | grep -c "Not licensed")

	if [ -f /sdcard/not_licensed ] && [ $not_licensed -gt 0 ]
	then
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Still unlicensed, exiting" >> $logfile
	elif [ $not_licensed -gt 0 ]
	then
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Device Lost Atlas License" >> $logfile
		[[ ! -z $discord_webhook ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas monitor\", \"content\": \"__**$origin**__: UNLICENSED !!! Check Atlas Dashboard\"}" $discord_webhook &>/dev/null
		touch /sdcard/not_licensed

	elif [ -f /sdcard/not_licensed ] && [ $not_licensed -eq 0 ]
	then
	        echo "`date +%Y-%m-%d_%T` [MONITORBOT] Device got License again. Recovering" >> $logfile
                [[ ! -z $discord_webhook ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas monitor\", \"content\": \"__**$origin**__: Device got Atlas license again\"}" $discord_webhook &>/dev/null
		rm /sdcard/not_licensed

        elif [ $emptycheck != 9 ] && [ $devicestatus != $deviceonline ] && [ $atlasdead == 2 ]
        then
                echo "`date +%Y-%m-%d_%T` [MONITORBOT] Atlas must be dead, rebooting device" >> $logfile
   	        [[ ! -z $discord_webhook ]] && [[ $atlas_died != "false" ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas monitor\", \"content\": \"__**$origin**__: atlas died, reboot\"}" $discord_webhook &>/dev/null
                reboot
        elif [ $emptycheck != 9 ] && [ $pogodead == 2 ]
        then
                echo "`date +%Y-%m-%d_%T` [MONITORBOT] Pogo must be dead, rebooting device" >> $logfile
   	        [[ ! -z $discord_webhook ]] && [[ $pogo_died != "false" ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas monitor\", \"content\": \"__**$origin**__: pogo died, reboot\"}" $discord_webhook &>/dev/null
                reboot

	elif [ $emptycheck != 9 ] && [ $devicestatus != $deviceonline ] && [ $atlasdead != 2 ]
	then
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Device must be offline. Running a stop mapping service of Atlas, killing pogo and clearing junk" >> $logfile
		[[ ! -z $discord_webhook ]] && [[ $device_offline != "false" ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas monitor\", \"content\": \"__**$origin**__: device offline, restarting atlas and pogo\"}" $discord_webhook &>/dev/null
		stop_start_atlas
		atlasdead=$((atlasdead+1))
		[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Done" >> $logfile

	elif [ $emptycheck == 9 ]
	then
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Couldn't check status, something wrong with RDM?" >> $logfile
		[[ ! -z $discord_webhook ]] && [[ $unable_check_status != "false" ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas monitor\", \"content\": \"__**$origin**__: unable to check status\"}" $discord_webhook &>/dev/null

	elif [ $deviceonline == $devicestatus ]
	then
		[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Atlas mapping service is running" >> $logfile
		atlasdead=0
		focusedapp=$(dumpsys window windows | grep -E 'mFocusedApp'| cut -d / -f 1 | cut -d " " -f 7)
		if [ "$focusedapp" != "com.nianticlabs.pokemongo" ]
		then
			echo "`date +%Y-%m-%d_%T` [MONITORBOT] Something is not right! Pogo is not in focus. Killing pogo and clearing junk" >> $logfile
			[[ ! -z $discord_webhook ]] && [[ $pogo_not_focused != "false" ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas monitor\", \"content\": \"__**$origin**__: pogo not in focus, Killing and clearing junk\"}" $discord_webhook &>/dev/null
			stop_pogo
			pogodead=$((pogodead+1))
			[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Done" >> $logfile
		else
			[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Pogo in focus, all good" >> $logfile
			pogodead=0
		fi
	else
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Something happened! Some kind of error" >> $logfile
		[[ ! -z $discord_webhook ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas monitor\", \"content\": \"__**$origin**__: no clue what happend, but its not good\"}" $discord_webhook &>/dev/null
	fi
	sleep $monitor_interval
done
