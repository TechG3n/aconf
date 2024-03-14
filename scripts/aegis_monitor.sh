#!/system/bin/sh
# version 3.3.3
#set -x

# Monitor by Oldmole && bbdoc

logfile="/sdcard/aegis_monitor.log"
aconf="/data/local/tmp/aegis_config.json"
origin=$(cat $aconf | tr , '\n' | grep -w 'deviceName' | awk -F "\"" '{ print $4 }')
android_version=`getprop ro.build.version.release | sed -e 's/\..*//'`
aegisdead=0
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

#Create logfile, stolen from aegis.sh
if [ ! -e /sdcard/aegis_monitor.log ] ;then
	touch /sdcard/aegis_monitor.log
fi

# stderr to logfile
exec 2>> $logfile

check_for_updates() {
	[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Checking for updates" >> $logfile
	/system/bin/aegis.sh -ua
}

stop_start_aegis () {
	am force-stop com.nianticlabs.pokemongo &  rm -rf /data/data/com.nianticlabs.pokemongo/cache/* 2>/dev/null & am force-stop com.pokemod.aegis 
	sleep 5
	[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Running the start mapping service of Aegis" >> $logfile

	if [ $android_version -ge 9 ]; then
		am start-foreground-service com.pokemod.aegis/com.pokemod.aegis.services.MappingService
	else
		am startservice com.pokemod.aegis/com.pokemod.aegis.services.MappingService
	fi
	
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
            "script": "aegis_monitor.sh"
        }
DATA
}


echo "`date +%Y-%m-%d_%T` [MONITORBOT] Starting aegis data monitor in 5 mins, loop is $monitor_interval seconds" >> $logfile
sleep 300
while :
do
	[[ $useMonitor == "false" ]] && echo "`date +%Y-%m-%d_%T` aegis_monitor stopped" >> $logfile && exit 1

	until ping -c1 8.8.8.8 >/dev/null 2>/dev/null
	do
		[[ $( awk '/./{line=$0} END{print line}' $logfile | grep 'No internet' | wc -l) != 1 ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] No internet, pay the bill?" >> $logfile
		sleep 60
	done

	[[ -z $origin ]] && origin=$(cat $aconf | tr , '\n' | grep -w 'deviceName' | awk -F "\"" '{ print $4 }')

        updatecheck=$(($updatecheck+1))
        if [[ $updatecheck -gt $update_check ]] ;then
		echo  "`date +%Y-%m-%d_%T` [MONITORBOT] Checking Aegis and Pogo for update" >> $logfile
		updatecheck=0
		check_for_updates
	fi

	if [ -d /data/data/com.pokemod.aegis ] && [ -s /data/local/tmp/aegis_config.json ]
	then
		[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] aegis_config.json looks good" >> $logfile
	else
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] aegis_config.json does not exist or is empty! Let's fix that" >> $logfile
		[[ ! -z $discord_webhook ]] && [[ $recreate_aegis_config != "false" ]] && curl -S -k -L --fail --show-error -F "payload_json={\"content\": \"__**$origin**__: re-creating aegis config\"}" $discord_webhook &>/dev/null
		/system/bin/aegis.sh -ic
		[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Fixed config" >> $logfile
		stop_start_aegis
		sleep $monitor_interval
		continue

	fi


	dumpsys activity services | grep -e "MappingService" > /dev/null 2>&1
	devicestatus=$(echo $?)
	emptycheck="9$devicestatus"

	not_licensed=$(tail -n 100 /data/local/tmp/aegis.log | grep -c -E "Not licensed|doesn't have a valid license")

	if [ -f /sdcard/not_licensed ] && [ $not_licensed -gt 0 ]
	then
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Still unlicensed, exiting" >> $logfile
	elif [ $not_licensed -gt 0 ]
	then
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Device Lost Aegis License" >> $logfile
		[[ ! -z $discord_webhook ]] && curl -S -k -L --fail --show-error -F "payload_json={\"content\": \"__**$origin**__: UNLICENSED !!! Check Aegis Dashboard\"}" $discord_webhook &>/dev/null
		[[ $useSender == "true" ]] && send_webhook "Lost Licence" "No action"
		touch /sdcard/not_licensed

	elif [ -f /sdcard/not_licensed ] && [ $not_licensed -eq 0 ]
	then
	    echo "`date +%Y-%m-%d_%T` [MONITORBOT] Device got License again. Recovering" >> $logfile
        [[ ! -z $discord_webhook ]] && curl -S -k -L --fail --show-error -F "payload_json={\"content\": \"__**$origin**__: Device got Aegis license again\"}" $discord_webhook &>/dev/null
		rm /sdcard/not_licensed

        elif [ $emptycheck != 9 ] && [ $devicestatus != $deviceonline ] && [ $aegisdead == 2 ]
        then
			echo "`date +%Y-%m-%d_%T` [MONITORBOT] Aegis must be dead, rebooting device" >> $logfile
			[[ $useSender == "true" ]] && send_webhook "Aegis Dead" "Reboot"
			[[ ! -z $discord_webhook ]] && [[ $aegis_died != "false" ]] && curl -S -k -L --fail --show-error -F "payload_json={\"content\": \"__**$origin**__: aegis died, reboot\"}" $discord_webhook &>/dev/null
			reboot
        elif [ $emptycheck != 9 ] && [ $pogodead == 2 ]
        then
            echo "`date +%Y-%m-%d_%T` [MONITORBOT] Pogo must be dead, rebooting device" >> $logfile
			[[ $useSender == "true" ]] && send_webhook "Pogo Dead" "Reboot"
   	        [[ ! -z $discord_webhook ]] && [[ $pogo_died != "false" ]] && curl -S -k -L --fail --show-error -F "payload_json={\"content\": \"__**$origin**__: pogo died, reboot\"}" $discord_webhook &>/dev/null
            reboot

	elif [ $emptycheck != 9 ] && [ $devicestatus != $deviceonline ] && [ $aegisdead != 2 ]
	then
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Device must be offline. Running a stop mapping service of Aegis, killing pogo and clearing junk" >> $logfile
		[[ $useSender == "true" ]] && send_webhook "Device Offline" "Kill Pogo and Clear Junk"
		[[ ! -z $discord_webhook ]] && [[ $device_offline != "false" ]] && curl -S -k -L --fail --show-error -F "payload_json={\"content\": \"__**$origin**__: device offline, restarting aegis and pogo\"}" $discord_webhook &>/dev/null
		stop_start_aegis
		aegisdead=$((aegisdead+1))
		[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Done" >> $logfile

	elif [ $emptycheck == 9 ]
	then
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Couldn't check status, something wrong with RDM?" >> $logfile
		[[ ! -z $discord_webhook ]] && [[ $unable_check_status != "false" ]] && curl -S -k -L --fail --show-error -F "payload_json={\"content\": \"__**$origin**__: unable to check status\"}" $discord_webhook &>/dev/null

	elif [ $deviceonline == $devicestatus ]
	then
		[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Aegis mapping service is running" >> $logfile
		aegisdead=0
		focusedapp=$(dumpsys window windows | grep -E 'mFocusedApp'| cut -d / -f 1 | cut -d " " -f 7)
		if [ "$focusedapp" != "com.nianticlabs.pokemongo" ]
		then
			echo "`date +%Y-%m-%d_%T` [MONITORBOT] Something is not right! Pogo is not in focus. Killing pogo and clearing junk" >> $logfile
		    [[ $useSender == "true" ]] && send_webhook "Pogo not in Focus" "Kill Pogo and Clear Junk"
			[[ ! -z $discord_webhook ]] && [[ $pogo_not_focused != "false" ]] && curl -S -k -L --fail --show-error -F "payload_json={\"content\": \"__**$origin**__: pogo not in focus, Killing and clearing junk\"}" $discord_webhook &>/dev/null
			stop_pogo
			pogodead=$((pogodead+1))
			[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Done" >> $logfile
		else
			[[ $debug == "true" ]] && echo "`date +%Y-%m-%d_%T` [MONITORBOT] Pogo in focus, all good" >> $logfile
			pogodead=0
		fi
	else
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Something happened! Some kind of error" >> $logfile
		[[ $useSender == "true" ]] && send_webhook "Unknown Error" "No action"
		[[ ! -z $discord_webhook ]] && curl -S -k -L --fail --show-error -F "payload_json={\"content\": \"__**$origin**__: no clue what happend, but its not good\"}" $discord_webhook &>/dev/null
	fi

	#get count of "[HEALTH CHECK] xx seconds since last ping." errors
	lastlog=$(tail -n 200 /data/local/tmp/aegis.log)
	healthcheckcount=$(echo "$lastlog" | grep -E '\[HEALTH CHECK\] ([0-9]+) seconds since last ping\.' | wc -l)
	crithealthcount=$(echo "$lastlog" | grep -E '\[HEALTH CHECK\] ([0-9]+) seconds since last ping\.' | awk '{if ($3 >= 30) count++} END {print count+0}')
	successcount=$(echo "$lastlog" | grep -E 'I \| Worker' | wc -l)
	if [ $healthcheckcount -ge 10 ] && [ $healthcheckcount -ge $successcount ] || [ $crithealthcount -ge 4 ] && [ $successcount -le 40 ] ; then
		if [[ $healthchecklock == 1 ]]; then
			#skip restart
			healthchecklock=0
		else
			stop_pogo
			echo "`date +%Y-%m-%d_%T` [MONITORBOT] Found $healthcheckcount Health Errors, $successcount successfull jobs and $crithealthcount crits - restarting Pogo" >> $logfile
			[[ ! -z $discord_webhook ]] && [[ $healthcheck_errors != "false" ]] && curl -S -k -L --fail --show-error -F "payload_json={\"content\": \"__**$origin**__: Found $healthcheckcount Health Errors, $successcount successfull jobs and $crithealthcount crits - restarting Pogo\"}" $discord_webhook &>/dev/null
			healthchecklock=1
		fi
	else
		healthchecklock=0
	fi

	# Instance 2's loop has been stalled for over a minute.. Restarting instance...
	stalled=$(echo "$lastlog" | grep -E 'loop has been stalled for over a minute' | wc -l )
	if [ $stalled -ge 1 ]; then
		if [[ $stalllock -ge 1 ]]; then
			#skip restart
			stalllock=$((stalllock - 1))
		else
			echo "`date +%Y-%m-%d_%T` [MONITORBOT] One instance stalled - restarting aegis" >> $logfile
			stop_start_aegis
			[[ ! -z $discord_webhook ]] && curl -S -k -L --fail --show-error -F "payload_json={\"content\": \"__**$origin**__: One instance stalled - restarting aegis\"}" $discord_webhook &>/dev/null
			stalllock=2
		fi
	else
		stalllock=$((stalllock - 1))
	fi
		
	sleep $monitor_interval
done