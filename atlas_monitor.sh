#!/system/bin/sh
# version 3.0.5
# Monitor by Oldmole

logfile="/sdcard/atlas_monitor.log"
aconf="/data/local/tmp/atlas_config.json"
origin=$(cat $aconf | tr , '\n' | grep -w 'deviceName' | awk -F "\"" '{ print $4 }')
atlasdead=0
pogodead=0
deviceonline="0"
emptycheck=9
updatecheck=0

source /data/local/aconf_versions
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
	[ $debug == "true" ] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Checking for updates" >> $logfile
	/system/bin/atlas.sh -ua
}

stop_start_command () {
	am force-stop com.nianticlabs.pokemongo & pm clear com.nianticlabs.pokemongo & am force-stop com.pokemod.atlas & pm clear com.pokemod.atlas
	sleep 5
	[ $debug == "true" ] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Running the start mapping service of Atlas" >> $logfile
	am startservice com.pokemod.atlas/com.pokemod.atlas.services.MappingService
	sleep 1

}

echo "`date +%Y-%m-%d_%T` [MONITORBOT] Starting atlas data monitor in 5 mins, loop is $monitor_interval seconds" >> $logfile
sleep 300
while :
do
	until ping -c1 8.8.8.8 >/dev/null 2>/dev/null
	do
		[[ $( awk '/./{line=$0} END{print line}' $logfile | grep 'No internet' | wc -l) != 1 ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] No internet, pay the bill?" >> $logfile
		sleep 60
	done

        updatecheck=$(($updatecheck+1))
        [[ $updatecheck -gt $update_check ]] && check_for_updates && updatecheck=0 && echo  "`date +%Y-%m-%d_%T` [MONITORBOT] Checking Atlas and Pogo for update" >> $logfile


	if [ -d /data/data/com.pokemod.atlas ] && [ -s /data/local/tmp/atlas_config.json ]
		then
			[ $debug == "true" ] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] atlas_config.json looks good" >> $logfile
	else
			echo "`date +%Y-%m-%d_%T` [MONITORBOT] atlas_config.json does not exist or is empty! Let's fix that" >> $logfile
			[[ ! -z $discord_webhook ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas monitor\", \"content\": \"$origin: re-creating atlas config\"}" $discord_webhook &>/dev/null
			/system/bin/atlas.sh -ic
			[ $debug == "true" ] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Fixed config" >> $logfile
			stop_start_command
			sleep $monitor_interval
			continue

	fi


	dumpsys activity services | grep -e "MappingService" > /dev/null 2>&1
	devicestatus=$(echo $?)
	emptycheck="9$devicestatus"

    if [ $emptycheck != 9 ] && [ $devicestatus != $deviceonline ] && [ $atlasdead == 2 ]
    then
        echo "`date +%Y-%m-%d_%T` [MONITORBOT] Atlas must be dead, rebooting device" >> $logfile
	[[ ! -z $discord_webhook ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas monitor\", \"content\": \"$origin: atlas died, reboot\"}" $discord_webhook &>/dev/null
        reboot
    elif [ $emptycheck != 9 ] && [ $pogodead == 2 ]
    then
        echo "`date +%Y-%m-%d_%T` [MONITORBOT] Pogo must be dead, rebooting device" >> $logfile
	[[ ! -z $discord_webhook ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas monitor\", \"content\": \"$origin: pogo died, reboot\"}" $discord_webhook &>/dev/null
        reboot

	elif [ $emptycheck != 9 ] && [ $devicestatus != $deviceonline ] && [ $atlasdead != 2 ]
	then
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Device must be offline. Running a stop mapping service of Atlas, killing pogo and clearing junk" >> $logfile
		[[ ! -z $discord_webhook ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas monitor\", \"content\": \"$origin: device offline, restaring atlas and pogo\"}" $discord_webhook &>/dev/null
		stop_start_command
		atlasdead=$((atlasdead+1))
		[ $debug == "true" ] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Done" >> $logfile

	elif [ $emptycheck == 9 ]
	then
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Couldn't check status, something wrong with RDM?" >> $logfile
		[[ ! -z $discord_webhook ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas monitor\", \"content\": \"$origin: unable to check status\"}" $discord_webhook &>/dev/null

	elif [ $deviceonline == $devicestatus ]
	then
		[ $debug == "true" ] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Atlas mapping service is running" >> $logfile
		atlasdead=0
		focusedapp=$(dumpsys window windows | grep -E 'mFocusedApp'| cut -d / -f 1 | cut -d " " -f 7)
		if [ "$focusedapp" != "com.nianticlabs.pokemongo" ]
		then
			echo "`date +%Y-%m-%d_%T` [MONITORBOT] Something is not right! Pogo is not in focus. Running a stop mapping service of Atlas, killing pogo and clearing junk" >> $logfile
			[[ ! -z $discord_webhook ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas monitor\", \"content\": \"$origin: pogo not in focus, restart atlas + pogo\"}" $discord_webhook &>/dev/null
			stop_start_command
			pogodead=$((pogodead+1))
			[ $debug == "true" ] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Done" >> $logfile
		else
			[ $debug == "true" ] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Pogo in focus, all good" >> $logfile
			pogodead=0
		fi
	else
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Something happened! Some kind of error" >> $logfile
		[[ ! -z $discord_webhook ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas monitor\", \"content\": \"$origin: no clue what happend, but its not good\"}" $discord_webhook &>/dev/null
	fi
	sleep $monitor_interval
done
