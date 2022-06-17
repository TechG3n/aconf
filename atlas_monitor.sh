#!/system/bin/sh
# version 3.0.0
# Monitor by Oldmole

logfile="/sdcard/atlas_monitor.log"
atlasdead=0
pogodead=0
deviceonline="0"
emptycheck=9
source /data/local/aconf_versions
export monitor_interval

#Create logfile, stolen from atlas.sh
if [ ! -e /sdcard/atlas_monitor.log ] ;then
	touch /sdcard/atlas_monitor.log
fi

check_for_updates() {
	echo "[MONITORBOT] Checking for updates" >> $logfile
	/system/bin/atlas.sh -ua
}

stop_start_command () {
	am force-stop com.nianticlabs.pokemongo & pm clear com.nianticlabs.pokemongo & am force-stop com.pokemod.atlas & pm clear com.pokemod.atlas
	sleep 5
	echo "[MONITORBOT] Running the start mapping service of Atlas" >> $logfile
	am startservice com.pokemod.atlas/com.pokemod.atlas.services.MappingService
	sleep 1

}

echo "[MONITORBOT] Starting up RDM data monitor in 5 mins, loop is $monitor_interval" >> $logfile
sleep 300
while :
do
	check_for_updates
	echo  "[MONITORBOT] Checking Atlas and Pogo" >> $logfile
	until ping -c1 8.8.8.8 >/dev/null 2>/dev/null
	do
		echo "[MONITORBOT] No internet, pay the bill?" >> $logfile
		sleep 60
	done

	if [ -d /data/data/com.pokemod.atlas ] && [ -s /data/local/tmp/atlas_config.json ]
		then
			echo "[MONITORBOT] atlas_config.json looks good" >> $logfile
	else
			echo "[MONITORBOT] atlas_config.json does not exist or is empty! Let's fix that" >> $logfile		
			/system/bin/atlas.sh -ic
			echo "[MONITORBOT] Fixed missing config" >> $logfile
			stop_start_command
			sleep $monitor_interval
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
		echo "[MONITORBOT] Running a stop mapping service of Atlas, killing pogo and clearing junk" >> $logfile
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
			echo "[MONITORBOT] Running a stop mapping service of Atlas, killing pogo and clearing junk" >> $logfile
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
	sleep $monitor_interval
done