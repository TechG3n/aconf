#!/system/bin/sh
# version 3.0.1
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
# to be removed
	echo "`date +%Y-%m-%d_%T` [MONITORBOT] Checking for updates" >> $logfile
	/system/bin/atlas.sh -ua
}

stop_start_command () {
	am force-stop com.nianticlabs.pokemongo & pm clear com.nianticlabs.pokemongo & am force-stop com.pokemod.atlas & pm clear com.pokemod.atlas
	sleep 5
# to be removed
	echo "`date +%Y-%m-%d_%T` [MONITORBOT] Running the start mapping service of Atlas" >> $logfile
	am startservice com.pokemod.atlas/com.pokemod.atlas.services.MappingService
	sleep 1

}

echo "`date +%Y-%m-%d_%T` [MONITORBOT] Starting atlas data monitor in 5 mins, loop is $monitor_interval" >> $logfile
sleep 300
while :
do
	check_for_updates
# to be removed
	echo  "`date +%Y-%m-%d_%T` [MONITORBOT] Checking Atlas and Pogo" >> $logfile
	until ping -c1 8.8.8.8 >/dev/null 2>/dev/null
	do
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] No internet, pay the bill?" >> $logfile
		sleep 60
	done

	if [ -d /data/data/com.pokemod.atlas ] && [ -s /data/local/tmp/atlas_config.json ]
		then
# to be removed
			echo "`date +%Y-%m-%d_%T` [MONITORBOT] atlas_config.json looks good" >> $logfile
	else
			echo "`date +%Y-%m-%d_%T` [MONITORBOT] atlas_config.json does not exist or is empty! Let's fix that" >> $logfile		
			/system/bin/atlas.sh -ic
# to be removed
			echo "`date +%Y-%m-%d_%T` [MONITORBOT] Fixed config" >> $logfile
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
#        echo "[MONITORBOT] Rebooting the unit..." >> $logfile
        reboot
    elif [ $emptycheck != 9 ] && [ $pogodead == 2 ]
    then
        echo "`date +%Y-%m-%d_%T` [MONITORBOT] Pogo must be dead, rebooting device" >> $logfile
#        echo "[MONITORBOT] Rebooting the unit..." >> $logfile
        reboot

	elif [ $emptycheck != 9 ] && [ $devicestatus != $deviceonline ] && [ $atlasdead != 2 ]
	then
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Device must be offline. Running a stop mapping service of Atlas, killing pogo and clearing junk" >> $logfile
#		echo "[MONITORBOT] Running a stop mapping service of Atlas, killing pogo and clearing junk" >> $logfile
		stop_start_command
		atlasdead=$((atlasdead+1))
# to be removed
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Done" >> $logfile

	elif [ $emptycheck == 9 ]
	then
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Couldn't check status, something wrong with RDM?" >> $logfile

	elif [ $deviceonline == $devicestatus ]
	then
# to be removed
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Atlas mapping service is running" >> $logfile
		atlasdead=0
		focusedapp=$(dumpsys window windows | grep -E 'mFocusedApp'| cut -d / -f 1 | cut -d " " -f 7)
		if [ "$focusedapp" != "com.nianticlabs.pokemongo" ]
		then
			echo "`date +%Y-%m-%d_%T` [MONITORBOT] Something is not right! Pogo is not in focus. Running a stop mapping service of Atlas, killing pogo and clearing junk" >> $logfile
#			echo "[MONITORBOT] Running a stop mapping service of Atlas, killing pogo and clearing junk" >> $logfile
			stop_start_command
			pogodead=$((pogodead+1))
# to be removed
			echo "`date +%Y-%m-%d_%T` [MONITORBOT] Done" >> $logfile
		else
# to be removed
			echo "[MONITORBOT] Pogo in focus, all good" >> $logfile
			pogodead=0
		fi
	else
		echo "`date +%Y-%m-%d_%T` [MONITORBOT] Something happened! Some kind of error" >> $logfile
	fi
	sleep $monitor_interval
done
