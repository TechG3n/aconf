#!/system/bin/sh
#Monitor by Oldmole Version:3
logfile="/sdcard/monitor.log"
atlasdead=0
pogodead=0
deviceonline="0"
emptycheck=9
source /sdcard/monitor.config
export myauthBearer mydeviceAuthToken myemail myrdmUrl blankcheck loopspeed

#Create logfile, stolen from atlas.sh
if [ ! -e /sdcard/monitor.log ] ;then
	touch /sdcard/monitor.log
fi

create_atlas_config () {
  device_name=$(cat /data/data/de.grennith.rgc.remotegpscontroller/shared_prefs/de.grennith.rgc.remotegpscontroller_preferences.xml | grep "websocket_origin" | sed 's/<[^>]*>//g' | xargs)
  rm /data/local/tmp/atlas_config.json
  touch /data/local/tmp/atlas_config.json
  printf \{\"authBearer\":\"$myauthBearer\",\"deviceAuthToken\":\"$mydeviceAuthToken\",\"deviceName\":\"$device_name\",\"email\":\"$myemail\",\"rdmUrl\":\"$myrdmUrl\",\"runOnBoot\":true\} > /data/local/tmp/atlas_config.json
  echo "[MONITORBOT] Running a stop mapping service of Atlas and clearing junk" >> $logfile
  am force-stop com.nianticlabs.pokemongo & pm clear com.nianticlabs.pokemongo & am force-stop com.pokemod.atlas & pm clear com.pokemod.atlas
  sleep 5
  echo "[MONITORBOT] Running the start mapping service of Atlas" >> $logfile
  am startservice com.pokemod.atlas/com.pokemod.atlas.services.MappingService
}

stop_start_command () {
	am force-stop com.nianticlabs.pokemongo & pm clear com.nianticlabs.pokemongo & am force-stop com.pokemod.atlas & pm clear com.pokemod.atlas
	sleep 5
	echo "[MONITORBOT] Running the start mapping service of Atlas" >> $logfile
	am startservice com.pokemod.atlas/com.pokemod.atlas.services.MappingService
	sleep 1

}

devicename=$(cat /data/data/de.grennith.rgc.remotegpscontroller/shared_prefs/de.grennith.rgc.remotegpscontroller_preferences.xml | grep "websocket_origin" | sed 's/<[^>]*>//g' | xargs)
echo "[MONITORBOT] Starting up RDM data monitor in 5 mins, loop is $loopspeed" >> $logfile
sleep 3 #was 300
while :
do
	echo  "[MONITORBOT] Checking Atlas and Pogo" >> $logfile
	until ping -c1 8.8.8.8 >/dev/null 2>/dev/null
	do
		echo "[MONITORBOT] No internet, pay the bill?" >> $logfile
		sleep 60
	done

	if [ -f /data/local/tmp/atlas_config.json ]
	then
		rdmurl=$(grep -o '"rdmUrl": *"[^"]*"' atlas_config.json | grep -o '"[^"]*"$' | cut -c 2-6)
		if [ $rdmurl != "$blankcheck" ] 
		then
			echo "Damn atlas_config.json is broken!! Let's fix that" >> $logfile
			create_atlas_config
			echo "[MONITORBOT] Fixed the broken config" >> $logfile
			sleep $loopspeed
			continue
		else
			echo "[MONITORBOT] atlas_config.json seems good" >> $logfile
		fi
	else
		echo "atlas_config.json does not exist!! Let's fix that" >> $logfile
		create_atlas_config
		echo "[MONITORBOT] Fixed missing config" >> $logfile
		sleep $loopspeed
		continue
	fi


	dumpsys activity services | grep -e "MappingService" > /dev/null 2>&1
	devicestatus=$(echo $?)
	emptycheck="9$devicestatus"

    if [ $emptycheck != 9 ] && [ $devicestatus != $deviceonline ] && [ $atlasdead == 2 ]
    then
        echo "[MONITORBOT] Atlas must be dead, dead" >> $logfile
        echo "[MONITORBOT] Rebooting the unit..." >> $logfile
        reboot
    elif [ $emptycheck != 9 ] && [ $pogodead == 2 ]
    then
        echo "[MONITORBOT] Pogo must be dead, dead" >> $logfile
        echo "[MONITORBOT] Rebooting the unit..." >> $logfile
        reboot

	elif [ $emptycheck != 9 ] && [ $devicestatus != $deviceonline ] && [ $atlasdead != 2 ]
	then
		echo "[MONITORBOT] Device must be offline" >> $logfile
		echo "[MONITORBOT] Running a stop mapping service of Atlas and clearing junk" >> $logfile
		stop_start_command
		atlasdead=$((atlasdead+1))
		echo "[MONITORBOT] Done" >> $logfile

	elif [ $emptycheck == 9 ]
	then
		echo "[MONITORBOT] Couldn't check status, something wrong with RDM?" >> $logfile

	elif [ $deviceonline == $devicestatus ]
	then
		echo "[MONITORBOT] Atlas mapping service is running" >> $logfile
		atlasdead=0
		focusedapp=$(dumpsys window windows | grep -E 'mFocusedApp'| cut -d / -f 1 | cut -d " " -f 7)
		if [ "$focusedapp" != "com.nianticlabs.pokemongo" ]
		then
			echo "[MONITORBOT] Something is not right! Pogo is not in focus" >> $logfile
			echo "[MONITORBOT] Running a stop mapping service of Atlas and clearing junk" >> $logfile
			stop_start_command
			pogodead=$((pogodead+1))
			echo "[MONITORBOT] Done" >> $logfile
		else
			echo "[MONITORBOT] Pogo in focus, all good" >> $logfile
			pogodead=0
		fi
	else
		echo "[MONITORBOT] Something happened! Some kind of error" >> $logfile
	fi
	sleep $loopspeed
done