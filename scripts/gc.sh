#!/system/bin/sh
# version 3.0.8

#Version checks
Ver42gc="1.6"
Ver55gc="1.2"
VerMonitor="4.0.3"
VerATVsender="2.0.0"

android_version=`getprop ro.build.version.release | sed -e 's/\..*//'`

#Create logfile
if [ ! -e /sdcard/aconf.log ] ;then
    touch /sdcard/aconf.log
fi

logfile="/sdcard/aconf.log"
aconf="/data/local/tmp/config.json"
aconf_versions="/data/local/aconf_versions"
aconf_mac2name="/data/local/aconf_mac2name"
[[ -f /data/local/aconf_download ]] && url=$(grep url /data/local/aconf_download | awk -F "=" '{ print $NF }')
[[ -f /data/local/aconf_download ]] && aconf_user=$(grep authUser /data/local/aconf_download | awk -F "=" '{ print $NF }')
[[ -f /data/local/aconf_download ]] && aconf_pass=$(grep authPass /data/local/aconf_download | awk -F "=" '{ print $NF }')
discord_webhook=$(grep 'discord_webhook' $aconf_versions | awk -F "=" '{ print $NF }' | sed -e 's/^"//' -e 's/"$//')
if [[ -z $discord_webhook ]] ;then
  discord_webhook=$(grep discord_webhook /data/local/aconf_download | awk -F "=" '{ print $NF }' | sed -e 's/^"//' -e 's/"$//')
fi

if [[ -f /data/local/tmp/config.json ]] ;then
# origin=$(grep -w 'deviceName' $aconf | awk -F "\"" '{ print $4 }')
  origin=$(cat $aconf | tr , '\n' | grep -w 'device_name' | awk -F "\"" '{ print $4 }')
else
  echo "`date +%Y-%m-%d_%T` gc.sh: cannot find origin, that can't be right" >> $logfile
fi

# stderr to logfile
exec 2>> $logfile

# add gc.sh command to log
echo "" >> $logfile
echo "`date +%Y-%m-%d_%T` gc.sh: executing $(basename $0) $@" >> $logfile
# echo "`date +%Y-%m-%d_%T` download folder set to $url, user is $aconf_user with pass $aconf_pass" >> $logfile


########## Functions

# logger
logger() {
  if [[ ! -z $discord_webhook ]] ;then
    echo "`date +%Y-%m-%d_%T` gc.sh: $1" >> $logfile
    if [[ -z $origin ]] ;then
      curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"gc.sh\", \"content\": \" $1 \"}"  $discord_webhook &>/dev/null
    else
      curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"gc.sh\", \"content\": \" $origin: $1 \"}"  $discord_webhook &>/dev/null
    fi
  else
    echo "`date +%Y-%m-%d_%T` gc.sh: $1" >> $logfile
  fi
}

reboot_device(){
  logger "rebooting device"
  sleep 2
  /system/bin/reboot
}

case "$(uname -m)" in
 aarch64) arch="arm64-v8a";;
 armv8l)  arch="armeabi-v7a";;
esac

mount_system_rw() {
  if [ $android_version -ge 9 ]; then
    # if a magisk module is installed that puts stuff under /system/etc, we're screwed, though.
    # because then /system/etc ends up full of bindmounts.. and you can't place new files under it.
    mount -o remount,rw /
  else
    mount -o remount,rw /system
    mount -o remount,rw /system/etc/init.d
  fi
}

mount_system_ro() {
  if [ $android_version -ge 9 ]; then
    mount -o remount,ro /
  else
    mount -o remount,ro /system
    mount -o remount,ro /system/etc/init.d
  fi
}

setup_initd_dir() {
  if [ $android_version -ge 9 ]; then
    mkdir -p /system/etc/init.d
    chmod 755 /system/etc/init.d
    chown root:root /system/etc/init.d
  fi
}

install_gc(){
  mount_system_rw
  setup_initd_dir
  if [ ! -f /system/etc/init.d/42gc ] ;then
    until $download /system/etc/init.d/55gc $url/scripts/55gc || { logger "download 55gc failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    chmod +x /system/etc/init.d/55gc
    logger "55gc installed"
  fi

if [ $android_version -ge 9 ]; then
    cat <<EOF > /system/etc/init/55gc.rc
on property:sys.boot_completed=1
    exec_background u:r:init:s0 root root -- /system/etc/init.d/55gc
EOF
    chown root:root /system/etc/init/55gc.rc
    chmod 644 /system/etc/init/55gc.rc
    logger "55gc.rc installed"
fi

  # install gc monitor
  until $download /system/bin/gc_monitor.sh $url/scripts/gc_monitor.sh || { logger "download gc_monitor.sh failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/bin/gc_monitor.sh
  logger "gc monitor installed"


if [ $android_version -ge 9 ]; then
                cat <<EOF > /system/etc/init/gc_monitor.rc
on property:sys.boot_completed=1
                exec_background u:r:init:s0 root root -- /system/bin/gc_monitor.sh
EOF
                chown root:root /system/etc/init/gc_monitor.rc
                chmod 644 /system/etc/init/gc_monitor.rc
                logger "gc_monitor.rc installed"

fi

  # install gcDetails sender
    until $download /system/bin/GcDetailsSender.sh $url/scripts/GcDetailsSender.sh || { logger "download GcDetailsSender.sh failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    chmod +x /system/bin/GcDetailsSender.sh
    logger "gcDetails sender installed"
    mount_system_ro

  # get version
  aversions=$(grep 'gc' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')

  # download gc
  /system/bin/rm -f /sdcard/Download/gc.apk
  until $download /sdcard/Download/gc.apk $url/apk/gc-$aversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/gc.apk $url/apk/gc-$aversions.apk" >> $logfile ; logger "download gc failed, exit script" ; exit 1; } ;do
    sleep 2
  done

  echo "`date +%Y-%m-%d_%T` gc.sh: gc (v: $aversions) downloaded for the first time" >> $logfile

  # let us kill pogo as well and clear data
  am force-stop com.nianticlabs.pokemongo > /dev/null 2>&1
  pm clear com.nianticlabs.pokemongo > /dev/null 2>&1

  # Install gc
  /system/bin/pm install -r /sdcard/Download/gc.apk > /dev/null 2>&1
  /system/bin/rm -f /sdcard/Download/gc.apk
  logger "gc installed"

  # Grant su access + settings
	euid="$(dumpsys package com.gocheats.launcher | /system/bin/grep userId | awk -F'=' '{print $2}')"
	magisk --sqlite "REPLACE INTO policies (uid,policy,until,logging,notification) VALUES($euid,2,0,1,1);"
  /system/bin/pm grant com.gocheats.launcher android.permission.READ_EXTERNAL_STORAGE
  /system/bin/pm grant com.gocheats.launcher android.permission.WRITE_EXTERNAL_STORAGE

  logger "gc granted su and settings set"

  # enable zygisk
  magisk --sqlite "REPLACE INTO settings (key,value) VALUES('zygisk',1);"

  # enable denylist
  magisk --sqlite "REPLACE INTO settings (key,value) VALUES('denylist',1);"
  magisk --denylist enable

  #global settings
  settings put global policy_control 'immersive.navigation=*'
  settings put global policy_control 'immersive.full=*'
  settings put secure immersive_mode_confirmations confirmed
  settings put global heads_up_enabled 0
  settings put global bluetooth_disabled_profiles 1
  settings put global bluetooth_on 0

  #download newest Pogo Lib file
  #todo
  #pogo_lib


  # download gc config file and adjust orgin to rgc setting
  install_config

  # check pogo version else remove+install
  downgrade_pogo

  # supress 'pink screen'
  opengl_warning

  # Set for reboot device
  reboot=1

  ## Send final webhook
  # discord_config_wh=$(grep 'discord_webhook' $aconf_versions | awk -F "=" '{ print $NF }')
  ip=$(ifconfig eth0 |grep 'inet addr' |cut -d ':' -f2 |cut -d ' ' -f1)
  logger "new gc device configured. IP: $ip"
}

#todo
install_config(){
  until $download /data/local/tmp/config.json $url/gc_config.json || { echo "`date +%Y-%m-%d_%T` $download /data/local/tmp/config.json $url/gc_config.json" >> $logfile ; logger "download gc config file failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  if [[ ! -z $origin ]] ;then
    sed -i 's,dummy,'$origin',g' $aconf
    logger "gc config installed, set devicename to $origin"
  else
    temporigin="TEMP-$(date +'%H_%M_%S')"
    sed -i 's,dummy,'$temporigin',g' $aconf
    logger "gc config installed, set devicename to $temporigin"
  fi
}

update_gc_config(){
  if [[ -z $origin ]] ;then
    logger "will not replace gc config file without deviceName being set"
  else
    until $download /data/local/tmp/config.json $url/gc_config.json || { echo "`date +%Y-%m-%d_%T` $download /data/local/tmp/config.json $url/gc_config.json" >> $logfile ; logger "download gc config file failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    sed -i 's,dummy,'$origin',g' $aconf

    am force-stop com.gocheats.launcher && sleep 2 && /system/bin/monkey -p com.gocheats.launcher 1 > /dev/null 2>&1

    logger "gc config updated and gc restarted"
  fi
}

update_all(){
  pinstalled=$(dumpsys package com.nianticlabs.pokemongo | grep versionName | head -n1 | sed 's/ *versionName=//')
  pversions=$(grep 'pogo' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')
  ainstalled=$(dumpsys package com.gocheats.launcher | /system/bin/grep versionName | head -n1 | /system/bin/sed 's/ *versionName=//')
  aversions=$(grep 'gc' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')

  if [[ $pinstalled != $pversions ]] ;then
    if [[ $(echo "$pinstalled" | tr '.' ' ' | awk '{print $1*10000+$2*100+$3}') -gt $(echo "$pversions" | tr '.' ' ' | awk '{print $1*10000+$2*100+$3}') ]]; then
      #This happens if playstore autoupdate is on or mad+rgc aren't configured correctly
      logger "pogo version is higher as it should, that shouldn't happen! ($pinstalled > $pversions)"
      downgrade_pogo
    else
      logger "new pogo version detected, $pinstalled=>$pversions"
      /system/bin/rm -f /sdcard/Download/pogo_*.apk
      until $download /sdcard/Download/pogo_base.apk $url/apk/pokemongo_$arch\_$pversions\_base.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/pogo_base.apk $url/apk/pokemongo_$arch\_$pversions\_base.apk" >> $logfile ; logger "download pogo base failed, exit script" ; exit 1; } ;do
        sleep 2
      done
      sleep 1
      until $download /sdcard/Download/pogo_split.apk $url/apk/pokemongo_$arch\_$pversions\_split.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/pogo_split.apk $url/apk/pokemongo_$arch\_$pversions\_split.apk" >> $logfile ; logger "download pogo split failed, exit script" ; exit 1; } ;do
        sleep 2
      done
      # set pogo to be installed
      pogo_install="install"
    fi
  else
  pogo_install="skip"
  echo "`date +%Y-%m-%d_%T` gc.sh: pogo already on correct version" >> $logfile
  fi

  if [ v$ainstalled != $aversions ] ;then
    logger "new gc version detected, $ainstalled=>$aversions"
    ver_gc_md5=$(grep 'gc_md5' $aconf_versions | awk -F "=" '{ print $NF }')
    if [[ ! -z $ver_gc_md5 ]] ;then
      inst_gc_md5=$(md5sum /data/app/com.pokemod.gc-*/base.apk | awk '{print $1}')
      if [[ $ver_gc_md5 == $inst_gc_md5 ]] ;then
        logger "New version but same md5 - skip install"
        gc_install="skip"
      else
        logger "New version, new md5 - start install"
        /system/bin/rm -f /sdcard/Download/gc.apk
        until $download /sdcard/Download/gc.apk $url/apk/gc-$aversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/gc.apk $url/apk/gc-$aversions.apk" >> $logfile ; logger "download gc failed, exit script" ; exit 1; } ;do
          sleep 2
        done
        # set gc to be installed
        gc_install="install"
      fi
    else
      logger "No md5 found, install new version regardless"
      /system/bin/rm -f /sdcard/Download/gc.apk
      until $download /sdcard/Download/gc.apk $url/apk/gc-$aversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/gc.apk $url/apk/gc-$aversions.apk" >> $logfile ; logger "download gc failed, exit script" ; exit 1; } ;do
        sleep 2
      done
      # set gc to be installed
      gc_install="install"
    fi
  else
    gc_install="skip"
    echo "`date +%Y-%m-%d_%T` gc.sh: gc already on correct version" >> $logfile
  fi

if [ ! -z "$gc_install" ] && [ ! -z "$pogo_install" ] ;then
  echo "`date +%Y-%m-%d_%T` gc.sh: all updates checked and downloaded if needed" >> $logfile
  if [ "$gc_install" = "install" ] ;then
    Logger "Updating gc"
    # install gc
    /system/bin/pm install -r /sdcard/Download/gc.apk || { logger "install gc failed, downgrade perhaps? Exit script" ; exit 1; }
    /system/bin/rm -f /sdcard/Download/gc.apk
    reboot=1
  fi
  if [ "$pogo_install" = "install" ] ;then
    logger "updating pogo"
    # install pogo
    /system/bin/pm install -r /sdcard/Download/pogo_base.apk && /system/bin/pm install -p com.nianticlabs.pokemongo -r /sdcard/Download/pogo_split.apk || { logger "install pogo failed, downgrade perhaps? Exit script" ; exit 1; }
    /system/bin/rm -f /sdcard/Download/pogo_*.apk
    reboot=1
  fi
  if [ "$gc_install" != "install" ] && [ "$pogo_install" != "install" ] ; then
    echo "`date +%Y-%m-%d_%T` gc.sh: updates checked, nothing to install" >> $logfile
  fi
fi

  # Force re-download of the config file at the next reboot. Turned on via versions file, should be turned off again
  force_config_update=$(grep 'force_config_update' $aconf_versions | awk -F "=" '{ print $NF }')
  if [[ $force_config_update == "true" ]] ;then
    logger "Forcing config reload - Don't forget to turn it back off!"
    install_config
  fi

  # check gc running
  gc_check=$(pgrep -fl -f 'com\.gocheats\.launcher')
  if [[ -z $gc_check ]] && [[ -f /data/local/tmp/config.json ]] ;then
    logger "gc not running, starting it"
    /system/bin/monkey -p com.gocheats.launcher 1 > /dev/null 2>&1
  fi

}

downgrade_pogo(){
  pinstalled=$(dumpsys package com.nianticlabs.pokemongo | grep versionName | head -n1 | sed 's/ *versionName=//')
  pversions=$(grep 'pogo' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')
  if [[ $pinstalled != $pversions ]] ;then
    /system/bin/rm -f /sdcard/Download/pogo_*.apk
    until $download /sdcard/Download/pogo_base.apk $url/apk/pokemongo_$arch\_$pversions\_base.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/pogo_base.apk $url/apk/pokemongo_$arch\_$pversions\_base.apk" >> $logfile ; logger "download pogo base failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    sleep 1
    until $download /sdcard/Download/pogo_split.apk $url/apk/pokemongo_$arch\_$pversions\_split.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/pogo_split.apk $url/apk/pokemongo_$arch\_$pversions\_base.apk" >> $logfile ; logger "download pogo split failed, exit script" ; exit 1; } ;do
      sleep 2
    done

    /system/bin/pm uninstall com.nianticlabs.pokemongo
    sleep 1
    am force-stop com.gocheats.launcher
    sleep 1
    /system/bin/pm install -r /sdcard/Download/pogo_base.apk && /system/bin/pm install -p com.nianticlabs.pokemongo -r /sdcard/Download/pogo_split.apk || { logger "install pogo failed while downgrading. Exit script" ; exit 1; }
    /system/bin/rm -f /sdcard/Download/pogo_*.apk
    logger "pogo removed and installed, now $pversions"
  else
    echo "`date +%Y-%m-%d_%T` gc.sh: pogo version correct, proceed" >> $logfile
  fi
}

send_logs(){
  if [[ -z $webhook ]] ;then
    echo "`date +%Y-%m-%d_%T` gc.sh: no webhook set in job" >> $logfile
  else
    # aconf log
    curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aconf log sender\", \"content\": \"aconf.log for $origin\"}" -F "file1=@$logfile" $webhook &>/dev/null
    # monitor log
    [[ -f /sdcard/gc_monitor.log ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aconf log sender\", \"content\": \"gc_monitor.log for $origin\"}" -F "file1=@/sdcard/gc_monitor.log" $webhook &>/dev/null
    # gc log
    cp /data/local/tmp/gc.log /sdcard/gc.log
    curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aconf log sender\", \"content\": \"gc.log for $origin\"}" -F "file1=@/sdcard/gc.log" $webhook &>/dev/null
    rm /sdcard/gc.log
    #logcat
    logcat -d > /sdcard/logcat.txt
    curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aconf log sender\", \"content\": \"logcat.txt for $origin\"}" -F "file1=@/sdcard/logcat.txt" $webhook &>/dev/null
    rm -f /sdcard/logcat.txt
    echo "`date +%Y-%m-%d_%T` gc.sh: sending logs to discord" >> $logfile
  fi
}

opengl_warning() {
  # Fetch OpenGL version and extract major version directly
  opengl_version=$(dumpsys SurfaceFlinger | grep -o "OpenGL ES [0-9]*\.[0-9]*" | sed -n 's/OpenGL ES \([0-9]*\)\..*/\1/p')

  # Check if major_version was successfully extracted
  if [[ -z "$opengl_version" ]]; then
      echo "`date +%Y-%m-%d_%T` gc.sh: [xml] failed to extract the OpenGL version."  >> $logfile
      return 1
  fi

  # Compare the major version number
  if [[ $opengl_version -ge 3 ]]; then
      echo "`date +%Y-%m-%d_%T` gc.sh: [xml] opengl is 3+, skipping" >> $logfile
  else
      echo "`date +%Y-%m-%d_%T` gc.sh: [xml] OpenGL version is less than 3. Downloading XML file." >> $logfile

      until $download /data/local/tmp/warning.xml $url/modules/warning.xml || { logger "download OpenGL XML failed, exit script" ; exit 1; } ;do
        sleep 2
      done

      # Push XML file to the device
      chown root:root /data/local/tmp/warning.xml
      mkdir -p /data/data/com.nianticlabs.pokemongo/shared_prefs/
      cp /data/local/tmp/warning.xml /data/data/com.nianticlabs.pokemongo/shared_prefs/com.nianticproject.holoholo.libholoholo.unity.UnityMainActivity.xml
  fi
}

########## Execution

#wait on internet
until ping -c1 8.8.8.8 >/dev/null 2>/dev/null || ping -c1 1.1.1.1 >/dev/null 2>/dev/null; do
    sleep 10
done
echo "`date +%Y-%m-%d_%T` gc.sh: internet connection available" >> $logfile

# verify download credential file and set download
if [[ ! -f /data/local/aconf_download ]] ;then
  logger "file /data/local/aconf_download not found, exit script" && exit 1
else
  if [[ $aconf_user == "" ]] ;then
    download="/system/bin/curl -s -k -L --fail --show-error -o"
  else
    download="/system/bin/curl -s -k -L --fail --show-error --user $aconf_user:$aconf_pass -o"
  fi
fi

#download latest gc.sh
if [[ $(basename $0) != "gc_new.sh" ]] ;then
  mount_system_rw
  oldsh=$(head -2 /system/bin/gc.sh | grep '# version' | awk '{ print $NF }')
  until $download /system/bin/gc_new.sh $url/scripts/gc.sh || { logger "download gc.sh failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/bin/gc_new.sh
  newsh=$(head -2 /system/bin/gc_new.sh | grep '# version' | awk '{ print $NF }')
  if [[ $oldsh != $newsh ]] ;then
    logger "gc.sh updated $oldsh=>$newsh, restarting script"
#   folder=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    cp /system/bin/gc_new.sh /system/bin/gc.sh
    mount_system_ro
    /system/bin/gc_new.sh $@
    exit 1
  fi
fi

# download latest version file
until $download $aconf_versions $url/versions || { echo "`date +%Y-%m-%d_%T` $download $aconf_versions $url/versions" >> $logfile ; logger "download gc versions file failed, exit script" ; exit 1; } ;do
  sleep 2
done
dos2unix $aconf_versions
echo "`date +%Y-%m-%d_%T` gc.sh: downloaded latest versions file"  >> $logfile

# download latest mac2name file
until $download $aconf_mac2name $url/mac2name || { echo "`date +%Y-%m-%d_%T` $download $aconf_mac2name $url/mac2name" >> $logfile ; logger "download gc mac2name file failed, skip naming" ; } ;do
  sleep 2
done
dos2unix $aconf_mac2name
echo "`date +%Y-%m-%d_%T` gc.sh: downloaded latest mac2name file"  >> $logfile
if [[ $origin = "" ]] ;then
  mac=$(ifconfig wlan0 2>/dev/null | grep 'HWaddr' | awk '{print $5}' | cut -d ' ' -f1 && ifconfig eth0 2>/dev/null | grep 'HWaddr' | awk '{print $5}')
  origin=$(grep -m 1 -i $mac $aconf_mac2name | cut -d ';' -f2)
  hostname=$origin
  if [[ $origin != "" ]] ;then
    echo "`date +%Y-%m-%d_%T` gc.sh: got origin name $origin from mac2name file"  >> $logfile
  else
    mac=$(ifconfig wlan0 2>/dev/null | grep 'HWaddr' | awk '{print $5}' | cut -d ' ' -f1 && ifconfig eth0 2>/dev/null | grep 'HWaddr' | awk '{print $5}')
    logger "no origin name found in mac2name file, add it with mac $mac"
  fi
fi


#update 42gc if needed
if [[ $(basename $0) = "gc_new.sh" ]] ;then
  if [[ -f /system/etc/init.d/42gc ]] ;then
    old42=$(head -2 /system/etc/init.d/42gc | grep '# version' | awk '{ print $NF }')
    if [ $Ver42gc != $old42 ] ;then
      mount_system_rw
      setup_initd_dir
      until $download /system/etc/init.d/42gc $url/scripts/42gc || { logger "download 42gc failed, exit script" ; exit 1; } ;do
        sleep 2
      done
      chmod +x /system/etc/init.d/42gc
      mount_system_ro
      new42=$(head -2 /system/etc/init.d/42gc | grep '# version' | awk '{ print $NF }')
      logger "42gc updated $old42=>$new42"
    fi
  fi
fi

#update 55gc if needed
if [[ $(basename $0) = "gc_new.sh" ]] ;then
  if [[ -f /system/etc/init.d/55gc ]] ;then
    old55=$(head -2 /system/etc/init.d/55gc | grep '# version' | awk '{ print $NF }')
    if [ $Ver55gc != $old55 ] ;then
      mount_system_rw
      setup_initd_dir
      until $download /system/etc/init.d/55gc $url/scripts/55gc || { logger "download 55gc failed, exit script" ; exit 1; } ;do
        sleep 2
      done
      chmod +x /system/etc/init.d/55gc
      mount_system_ro
      new55=$(head -2 /system/etc/init.d/55gc | grep '# version' | awk '{ print $NF }')
      logger "55gc updated $old55=>$new55"
    fi
  fi
fi

#update gc monitor if needed
if [[ $(basename $0) = "gc_new.sh" ]] ;then
  [ -f /system/bin/gc_monitor.sh ] && oldMonitor=$(head -2 /system/bin/gc_monitor.sh | grep '# version' | awk '{ print $NF }') || oldMonitor="0"
  if [ $VerMonitor != $oldMonitor ] ;then
    mount_system_rw
    until $download /system/bin/gc_monitor.sh $url/scripts/gc_monitor.sh || { logger "download gc_monitor.sh failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    chmod +x /system/bin/gc_monitor.sh
    mount_system_ro
    newMonitor=$(head -2 /system/bin/gc_monitor.sh | grep '# version' | awk '{ print $NF }')
    logger "gc monitor updated $oldMonitor => $newMonitor"

    # restart gc monitor
    if [[ $(grep useMonitor $aconf_versions | awk -F "=" '{ print $NF }') == "true" ]] && [ -f /system/bin/gc_monitor.sh ] ;then
      checkMonitor=$(pgrep -f /system/bin/gc_monitor.sh)
      if [ ! -z $checkMonitor ] ;then
        kill -9 $checkMonitor
        sleep 2
        /system/bin/gc_monitor.sh >/dev/null 2>&1 &
        logger "gc monitor restarted"
      fi
    fi
  fi
fi

#update gcDetails sender if needed
if [[ $(basename $0) = "gc_new.sh" ]] ;then
  [ -f /system/bin/GcDetailsSender.sh ] && oldSender=$(head -2 /system/bin/GcDetailsSender.sh | grep '# version' | awk '{ print $NF }') || oldSender="0"
  if [ $VerATVsender != $oldSender ] ;then
    mount_system_rw
    until $download /system/bin/GcDetailsSender.sh $url/scripts/GcDetailsSender.sh || { logger "download GcDetailsSender.sh failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    chmod +x /system/bin/GcDetailsSender.sh
    mount_system_ro
    newSender=$(head -2 /system/bin/GcDetailsSender.sh | grep '# version' | awk '{ print $NF }')
    logger "gcDetails sender updated $oldSender => $newSender"

    # restart gcDetails sender
    if [[ $(grep useSender $aconf_versions | awk -F "=" '{ print $NF }') == "true" ]] && [ -f /system/bin/GcDetailsSender.sh ] ;then
      checkSender=$(pgrep -f /system/bin/GcDetailsSender.sh)
      if [ ! -z $checkSender ] ;then
        kill -9 $checkSender
        sleep 2
      fi
      /system/bin/GcDetailsSender.sh >/dev/null 2>&1 &
      logger "gcDetails sender (re)started"
    fi
  fi
fi


# prevent aconf causing reboot loop. Add bypass ?? <- done :)
loop_protect_enabled=$(grep 'loop_protect_enabled' $aconf_versions | awk -F "=" '{ print $NF }')
if [[ $(cat /sdcard/aconf.log | grep `date +%Y-%m-%d` | grep rebooted | grep -v "over 20 times" | wc -l) -gt 20 ]] ;then
  if [[ $loop_protect_enabled != "false" ]] ;then
    logger "device rebooted over 20 times today, gc.sh signing out, see you tomorrow"
    exit 1
  else
    logger "device rebooted over 20 times today, BUT loop protect is disabled, will continue - Don't forget to turn it back on!"
  fi
fi

# set hostname = origin, wait till next reboot for it to take effect
if [[ $origin != "" ]] ;then
  if [ $(cat /system/build.prop | grep net.hostname | wc -l) = 0 ]; then
    mount_system_rw
    logger "no hostname set, setting it to $origin"
    if [ -n "$(tail -c 1 /system/build.prop)" ]; then
      echo "" >> /system/build.prop
    fi
    echo "net.hostname=$origin" >> /system/build.prop
    mount_system_ro
  else
    hostname=$(grep net.hostname /system/build.prop | awk 'BEGIN { FS = "=" } ; { print $2 }')
    if [[ $hostname != $origin ]] && [[ $origin != "dummy" ]] ;then
      mount_system_rw
      logger "changing hostname, from $hostname to $origin"
      sed -i -e "s/^net.hostname=.*/net.hostname=$origin/g" /system/build.prop
      mount_system_ro
    fi
  fi
fi

# check gc config file exists
if [[ ! -s $aconf ]] ;then
  install_config
  am force-stop com.gocheats.launcher && sleep 2 && /system/bin/monkey -p com.gocheats.launcher 1 > /dev/null 2>&1
fi

# check 16/42mad pogo autoupdate disabled
! [[ -f /sdcard/disableautopogoupdate ]] && touch /sdcard/disableautopogoupdate

# check for webhook
if [[ $2 == https://* ]] ;then
  webhook=$2
fi

# enable gc monitor
if [[ $(grep useMonitor $aconf_versions | awk -F "=" '{ print $NF }' | awk '{ gsub(/ /,""); print }') == "true" ]] && [ -f /system/bin/gc_monitor.sh ] ;then
  checkMonitor=$(pgrep -f /system/bin/gc_monitor.sh)
  if [ -z $checkMonitor ] ;then
    /system/bin/gc_monitor.sh >/dev/null 2>&1 &
    echo "`date +%Y-%m-%d_%T` gc.sh: gc monitor enabled" >> $logfile
  fi
fi

# enable gcDetails sender
if [[ $(grep useSender $aconf_versions | awk -F "=" '{ print $NF }' | awk '{ gsub(/ /,""); print }') == "true" ]] && [ -f /system/bin/GcDetailsSender.sh ] ;then
  checkSender=$(pgrep -f /system/bin/GcDetailsSender.sh)
  if [ -z $checkSender ] ;then
    /system/bin/GcDetailsSender.sh >/dev/null 2>&1 &
    echo "`date +%Y-%m-%d_%T` gc.sh: gcDetails sender started" >> $logfile
  fi
fi

# check gc running
gc_check=$(pgrep -fl -f 'com\.nianticlabs\.pokemongo')
if [[ -z $gc_check ]] && [[ -f /data/local/tmp/config.json ]] ;then
  logger "gc not running at execution of gc.sh, starting it"
  /system/bin/monkey -p com.gocheats.launcher 1 > /dev/null 2>&1
fi

# check if playstore is enabled
if [ "$(pm list packages -d com.android.vending)" = "package:com.android.vending" ] ;then
  logger "Enabling Play Store"
  pm enable com.android.vending
fi

# disable PlayIntegrity APK verification
play_integrity=$(grep 'play_integrity' $aconf_versions | awk -F "=" '{ print $NF }')
pintegrity=$(settings get global package_verifier_user_consent)
if [[ $play_integrity != "false" ]] && [[ $pintegrity == 1 ]]; then
  settings put global package_verifier_user_consent -1
  logger "disabled PlayIntegrity APK verification"
fi

# disable APKM verification
play_integrity=$(grep 'play_integrity' $aconf_versions | awk -F "=" '{ print $NF }')
apkmverify=$(settings get global package_verifier_enable)
if [[ $play_integrity != "false" ]] && [[ $apkmverify == 1 ]]; then
  settings put global package_verifier_enable 0
  logger "disabled APKM verification"
fi

# update playintegrityfix magisk modul if needed
versionsPIFv=$(grep 'PIF_module' $aconf_versions | awk -F "=" '{ print $NF }' | sed 's/\"//g')

if [[ ! -z $versionsPIFv ]] ;then
  # get installed version
  instPIFv=$(grep 'version=' /data/adb/modules/playintegrityfix/module.prop | awk -F "=v" '{ print $NF }')
  [ -z "$instPIFv" ] && instPIFv=0
  if [[ $instPIFv != $versionsPIFv ]] ;then
    /system/bin/rm -f /sdcard/Download/PIF_module.zip
    until $download /sdcard/Download/PIF_module.zip $url/modules/PlayIntegrityFix_v$versionsPIFv.zip || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/PIF_module.zip $url/modules/PlayIntegrityFix_v$versionsPIFv.zip" >> $logfile ; logger "download PIF_module failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    am force-stop com.nianticlabs.pokemongo
    /sbin/magisk --install-module /sdcard/Download/PIF_module.zip
    logger "Updated PIF module from $instPIFv to $versionsPIFv"
    reboot=1
  else
    echo "`date +%Y-%m-%d_%T` gc.sh: PIF module correct, proceed" >> $logfile
  fi
fi


# update Fingerprint if needed
versionsFingerPrintv=$(grep 'FingerPrintVersion' $aconf_versions | awk -F "=" '{ print $NF }' | sed 's/\"//g')

if [[ ! -z $versionsFingerPrintv ]] ;then
  # get installed version
  instFingerPrintv=$(cat /data/local/tmp/fingerprint.version)
  [ -z "$instFingerPrintv" ] && instFingerPrintv=0
  if [[ $instFingerPrintv -lt $versionsFingerPrintv ]] ;then
    /system/bin/rm -f /sdcard/Download/pif.json
    until $download /sdcard/Download/pif.json $url/modules/pif.json || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/pif.json $url/modules/pif.json" >> $logfile ; logger "download FingerPrint failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    cp /sdcard/Download/pif.json /data/adb/pif.json
    logger "Updated FingerPrint from $instFingerPrintv to $versionsFingerPrintv"
    echo $versionsFingerPrintv > /data/local/tmp/fingerprint.version
    /system/bin/killall com.google.android.gms.unstable
    #reboot=1
  else
    echo "`date +%Y-%m-%d_%T` gc.sh: FingerPrint correct, proceed" >> $logfile
  fi
fi


# start custom job if set
versionsCJv=$(grep 'CustomeJob' $aconf_versions | awk -F "=" '{ print $NF }' | sed 's/\"//g')

if [[ ! -z $versionsCJv ]] && [[ "$versionsCJv" != "0" ]] ;then
  # get installed version
  instCJv=$(head -2 /data/local/tmp/aconf-cj.sh 2>/dev/null | grep '# version' | awk '{ print $NF }')
  [ -z "$instCJv" ] && instCJv=0
  if [[ $instCJv -lt $versionsCJv ]] ;then
    /system/bin/rm -f /data/local/tmp/aconf-cj.sh
    until $download /data/local/tmp/aconf-cj.sh $url/jobs/customJob.sh || { echo "`date +%Y-%m-%d_%T` $download /data/local/tmp/aconf-cj.sh $url/jobs/customJob.sh" >> $logfile ; logger "download CustomJob failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    logger "Updated CustomJob from $instCJv to $versionsCJv. Starting it"
    chmod +x /data/local/tmp/aconf-cj.sh
    /data/local/tmp/aconf-cj.sh >/dev/null 2>&1 &
  else
    echo "`date +%Y-%m-%d_%T` gc.sh: CustomJob Up2Date, proceed" >> $logfile
  fi
fi


for i in "$@" ;do
 case "$i" in
 -ia) install_gc ;;
 -ic) install_config ;;
 -ua) update_all ;;
 -uac) update_gc_config ;;
 -sl) send_logs;;
# consider adding: downgrade gc, update donwload link
 esac
done


(( $reboot )) && reboot_device
exit
