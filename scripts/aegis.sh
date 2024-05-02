#!/system/bin/sh
# version 2.2.0

#Version checks
Ver42aegis="1.5"
Ver55aegis="1.0"
VerMonitor="3.4.0"
VerATVsender="1.9.0"

android_version=`getprop ro.build.version.release | sed -e 's/\..*//'`

#Create logfile
if [ ! -e /sdcard/aconf.log ] ;then
    touch /sdcard/aconf.log
fi

logfile="/sdcard/aconf.log"
[[ -d /data/data/com.mad.pogodroid ]] && puser=$(ls -la /data/data/com.mad.pogodroid/ | head -n2 | tail -n1 | awk '{print $3}')
pdconf="/data/data/com.mad.pogodroid/shared_prefs/com.mad.pogodroid_preferences.xml"
[[ -d /data/data/de.grennith.rgc.remotegpscontroller ]] && ruser=$(ls -la /data/data/de.grennith.rgc.remotegpscontroller/ |head -n2 | tail -n1 | awk '{print $3}')
rgcconf="/data/data/de.grennith.rgc.remotegpscontroller/shared_prefs/de.grennith.rgc.remotegpscontroller_preferences.xml"
aconf="/data/local/tmp/aegis_config.json"
aconf_versions="/data/local/aconf_versions"
aconf_mac2name="/data/local/aconf_mac2name"
[[ -f /data/local/aconf_download ]] && url=$(grep url /data/local/aconf_download | awk -F "=" '{ print $NF }')
[[ -f /data/local/aconf_download ]] && aconf_user=$(grep authUser /data/local/aconf_download | awk -F "=" '{ print $NF }')
[[ -f /data/local/aconf_download ]] && aconf_pass=$(grep authPass /data/local/aconf_download | awk -F "=" '{ print $NF }')
discord_webhook=$(grep 'discord_webhook' $aconf_versions | awk -F "=" '{ print $NF }' | sed -e 's/^"//' -e 's/"$//')
if [[ -z $discord_webhook ]] ;then
  discord_webhook=$(grep discord_webhook /data/local/aconf_download | awk -F "=" '{ print $NF }' | sed -e 's/^"//' -e 's/"$//')
fi

if [[ -f /data/local/tmp/aegis_config.json ]] ;then
# origin=$(grep -w 'deviceName' $aconf | awk -F "\"" '{ print $4 }')
  origin=$(cat $aconf | tr , '\n' | grep -w 'deviceName' | awk -F "\"" '{ print $4 }')
else
  if [[ -f /data/data/de.grennith.rgc.remotegpscontroller/shared_prefs/de.grennith.rgc.remotegpscontroller_preferences.xml ]] ;then
    origin=$(grep -w 'websocket_origin' $rgcconf | sed -e 's/    <string name="websocket_origin">\(.*\)<\/string>/\1/')
  else
    echo "`date +%Y-%m-%d_%T` aegis.sh: cannot find origin, that can't be right" >> $logfile
  fi
fi

# stderr to logfile
exec 2>> $logfile

# add aegis.sh command to log
echo "" >> $logfile
echo "`date +%Y-%m-%d_%T` aegis.sh: executing $(basename $0) $@" >> $logfile
# echo "`date +%Y-%m-%d_%T` download folder set to $url, user is $aconf_user with pass $aconf_pass" >> $logfile


########## Functions

# logger
logger() {
if [[ ! -z $discord_webhook ]] ;then
  echo "`date +%Y-%m-%d_%T` aegis.sh: $1" >> $logfile
  if [[ -z $origin ]] ;then
    curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aegis.sh\", \"content\": \" $1 \"}"  $discord_webhook &>/dev/null
  else
    curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aegis.sh\", \"content\": \" $origin: $1 \"}"  $discord_webhook &>/dev/null
  fi
else
  echo "`date +%Y-%m-%d_%T` aegis.sh: $1" >> $logfile
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

install_aegis(){
  mount_system_rw
  setup_initd_dir
if [ ! -f /system/etc/init.d/42aegis ] ;then
  until $download /system/etc/init.d/55aegis $url/scripts/55aegis || { logger "download 55aegis failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/etc/init.d/55aegis
  logger "55aegis installed"
fi

if [ $android_version -ge 9 ]; then
    cat <<EOF > /system/etc/init/55aegis.rc
on property:sys.boot_completed=1
    exec_background u:r:init:s0 root root -- /system/etc/init.d/55aegis
EOF
    chown root:root /system/etc/init/55aegis.rc
    chmod 644 /system/etc/init/55aegis.rc
    logger "55aegis.rc installed"
fi

# install aegis monitor
  until $download /system/bin/aegis_monitor.sh $url/scripts/aegis_monitor.sh || { logger "download aegis_monitor.sh failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/bin/aegis_monitor.sh
  logger "aegis monitor installed"


if [ $android_version -ge 9 ]; then
                cat <<EOF > /system/etc/init/aegis_monitor.rc
on property:sys.boot_completed=1
                exec_background u:r:init:s0 root root -- /system/bin/aegis_monitor.sh
EOF
                chown root:root /system/etc/init/aegis_monitor.rc
                chmod 644 /system/etc/init/aegis_monitor.rc
                logger "aegis_monitor.rc installed"

fi

# install AegisDetails sender
  until $download /system/bin/AegisDetailsSender.sh $url/scripts/AegisDetailsSender.sh || { logger "download AegisDetailsSender.sh failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/bin/AegisDetailsSender.sh
  logger "AegisDetails sender installed"
  mount_system_ro

# get version
aversions=$(grep 'aegis' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')

# download aegis
/system/bin/rm -f /sdcard/Download/aegis.apk
until $download /sdcard/Download/aegis.apk $url/apk/PokemodAegis-Public-$aversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/aegis.apk $url/apk/PokemodAegis-Public-$aversions.apk" >> $logfile ; logger "download aegis failed, exit script" ; exit 1; } ;do
  sleep 2
done

# pogodroid disable full daemon + stop pogodroid
if [ -f "$pdconf" ] ;then
  sed -i 's,\"full_daemon\" value=\"true\",\"full_daemon\" value=\"false\",g' $pdconf
  chmod 660 $pdconf
  chown $puser:$puser $pdconf
  am force-stop com.mad.pogodroid
  logger "pogodroid disabled"
  # disable pd autoupdate
  touch /sdcard/disableautopogodroidupdate
fi

#disable pogo update by 42mad
touch /sdcard/disableautopogoupdate

# let us kill pogo as well and clear data
am force-stop com.nianticlabs.pokemongo
pm clear com.nianticlabs.pokemongo

# Install aegis
/system/bin/pm install -r /sdcard/Download/aegis.apk
/system/bin/rm -f /sdcard/Download/aegis.apk
logger "aegis installed"

# Grant su access + settings
auid="$(dumpsys package com.pokemod.aegis | grep userId | awk -F'=' '{print $2}')"
magisk --sqlite "DELETE from policies WHERE package_name='com.pokemod.aegis'"
magisk --sqlite "INSERT INTO policies (uid,package_name,policy,until,logging,notification) VALUES($auid,'com.pokemod.aegis',2,0,1,0)"
pm grant com.pokemod.aegis android.permission.READ_EXTERNAL_STORAGE
pm grant com.pokemod.aegis android.permission.WRITE_EXTERNAL_STORAGE
logger "aegis granted su and settings set"

# download aegis config file and adjust orgin to rgc setting
install_config

# check pogo version else remove+install
downgrade_pogo

# check if rgc is to be enabled or disabled
check_rgc

# start aegis

if [ $android_version -ge 9 ]; then
  am start-foreground-service com.pokemod.aegis/com.pokemod.aegis.services.MappingService
else
  am startservice com.pokemod.aegis/com.pokemod.aegis.services.MappingService
  sleep 15
fi

# Set for reboot device
reboot=1

## Send final webhook
# discord_config_wh=$(grep 'discord_webhook' $aconf_versions | awk -F "=" '{ print $NF }')
ip=$(ifconfig eth0 |grep 'inet addr' |cut -d ':' -f2 |cut -d ' ' -f1)
logger "new aegis device configured. IP: $ip"

}

install_config(){
until $download /data/local/tmp/aegis_config.json $url/aegis_config.json || { echo "`date +%Y-%m-%d_%T` $download /data/local/tmp/aegis_config.json $url/aegis_config.json" >> $logfile ; logger "download aegis config file failed, exit script" ; exit 1; } ;do
  sleep 2
done
if [[ ! -z $origin ]] ;then
  sed -i 's,dummy,'$origin',g' $aconf
  logger "aegis config installed, set devicename to $origin"
else
  temporigin="TEMP-$(date +'%H_%M_%S')"
  sed -i 's,dummy,'$temporigin',g' $aconf
  logger "aegis config installed, set devicename to $temporigin"
fi
}

update_aegis_config(){
if [[ -z $origin ]] ;then
  logger "will not replace aegis config file without deviceName being set"
else
  until $download /data/local/tmp/aegis_config.json $url/aegis_config.json || { echo "`date +%Y-%m-%d_%T` $download /data/local/tmp/aegis_config.json $url/aegis_config.json" >> $logfile ; logger "download aegis config file failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  sed -i 's,dummy,'$origin',g' $aconf

  if [ $android_version -ge 9 ]; then
    am force-stop com.pokemod.aegis && am start-foreground-service com.pokemod.aegis/com.pokemod.aegis.services.MappingService
  else
    am force-stop com.pokemod.aegis && am startservice com.pokemod.aegis/com.pokemod.aegis.services.MappingService
  fi

  logger "aegis config updated and aegis restarted"
fi
}

update_all(){
pinstalled=$(dumpsys package com.nianticlabs.pokemongo | grep versionName | head -n1 | sed 's/ *versionName=//')
pversions=$(grep 'pogo' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')
ainstalled=$(dumpsys package com.pokemod.aegis | grep versionName | head -n1 | sed 's/ *versionName=//' | sed 's/-fix//' )
aversions=$(grep 'aegis' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')

if [[ $pinstalled != $pversions ]] ;then
  if [[ $(echo "$pinstalled" | tr '.' ' ' | awk '{print $1*10000+$2*100+$3}') -gt $(echo "$pversions" | tr '.' ' ' | awk '{print $1*10000+$2*100+$3}') ]]; then
    #This happens if playstore autoupdate is on or mad+rgc aren't configured correctly
    logger "pogo version is higher as it should, that shouldn't happen! ($pinstalled > $pversions)"
    downgrade_pogo
  else
    logger "new pogo version detected, $pinstalled=>$pversions"
    /system/bin/rm -f /sdcard/Download/pogo.apk
    until $download /sdcard/Download/pogo.apk $url/apk/pokemongo_$arch\_$pversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/pogo.apk $url/apk/pokemongo_$arch\_$pversions.apk" >> $logfile ; logger "download pogo failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    # set pogo to be installed
    pogo_install="install"
  fi
else
 pogo_install="skip"
 echo "`date +%Y-%m-%d_%T` aegis.sh: pogo already on correct version" >> $logfile
fi

if [ v$ainstalled != $aversions ] ;then
  logger "new aegis version detected, $ainstalled=>$aversions"
  ver_aegis_md5=$(grep 'aegis_md5' $aconf_versions | awk -F "=" '{ print $NF }')
  if [[ ! -z $ver_aegis_md5 ]] ;then
    inst_aegis_md5=$(md5sum /data/app/com.pokemod.aegis-*/base.apk | awk '{print $1}')
    if [[ $ver_aegis_md5 == $inst_aegis_md5 ]] ;then
      logger "New version but same md5 - skip install"
      aegis_install="skip"
    else
      logger "New version, new md5 - start install"
      /system/bin/rm -f /sdcard/Download/aegis.apk
      until $download /sdcard/Download/aegis.apk $url/apk/PokemodAegis-Public-$aversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/aegis.apk $url/apk/PokemodAegis-Public-$aversions.apk" >> $logfile ; logger "download aegis failed, exit script" ; exit 1; } ;do
        sleep 2
      done
      # set aegis to be installed
      aegis_install="install"
    fi
  else
    logger "No md5 found, install new version regardless"
    /system/bin/rm -f /sdcard/Download/aegis.apk
    until $download /sdcard/Download/aegis.apk $url/apk/PokemodAegis-Public-$aversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/aegis.apk $url/apk/PokemodAegis-Public-$aversions.apk" >> $logfile ; logger "download aegis failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    # set aegis to be installed
    aegis_install="install"
  fi
else
 aegis_install="skip"
 echo "`date +%Y-%m-%d_%T` aegis.sh: aegis already on correct version" >> $logfile
fi

if [ ! -z "$aegis_install" ] && [ ! -z "$pogo_install" ] ;then
  echo "`date +%Y-%m-%d_%T` aegis.sh: all updates checked and downloaded if needed" >> $logfile
  if [ "$aegis_install" = "install" ] ;then
    Logger "Updating aegis"
    # install aegis
    /system/bin/pm install -r /sdcard/Download/aegis.apk || { logger "install aegis failed, downgrade perhaps? Exit script" ; exit 1; }
    /system/bin/rm -f /sdcard/Download/aegis.apk
    reboot=1
  fi
  if [ "$pogo_install" = "install" ] ;then
    logger "updating pogo"
    # install pogo
    /system/bin/pm install -r /sdcard/Download/pogo.apk || { logger "install pogo failed, downgrade perhaps? Exit script" ; exit 1; }
    /system/bin/rm -f /sdcard/Download/pogo.apk
    reboot=1
  fi
  if [ "$aegis_install" != "install" ] && [ "$pogo_install" != "install" ] ; then
    echo "`date +%Y-%m-%d_%T` aegis.sh: updates checked, nothing to install" >> $logfile
  fi
fi
}

check_rgc(){
if [ -f "$rgcconf" ] ;then
  rgccheck=$(grep 'rgc' $aconf_versions | awk -F "=" '{ print $NF }')
  rgcstatus=$(grep -w 'boot_startup' $rgcconf | awk -F "\"" '{print tolower($4)}')
  if [[ $rgccheck == "off" ]] && [[ $rgcstatus == "true" ]] ;then
    # disable rgc
    sed -i 's,\"autostart_services\" value=\"true\",\"autostart_services\" value=\"false\",g' $rgcconf
    sed -i 's,\"boot_startup\" value=\"true\",\"boot_startup\" value=\"false\",g' $rgcconf
    chmod 660 $rgcconf
    chown $ruser:$ruser $rgcconf
    # disable rgc autoupdate
    touch /sdcard/disableautorgcupdate
    # kill rgc
    am force-stop de.grennith.rgc.remotegpscontroller
    logger "disabled rgc"
  fi
  if [[ $rgccheck == "on" ]] && [[ $rgcstatus == "false" ]] ;then
    # enable rgc
    sed -i 's,\"autostart_services\" value=\"false\",\"autostart_services\" value=\"true\",g' $rgcconf
    sed -i 's,\"boot_startup\" value=\"false\",\"boot_startup\" value=\"true\",g' $rgcconf
    chmod 660 $rgcconf
    chown $ruser:$ruser $rgcconf
    # start rgc
    monkey -p de.grennith.rgc.remotegpscontroller 1
    logger "enabled and started rgc"
  fi
fi
}

downgrade_pogo(){
pinstalled=$(dumpsys package com.nianticlabs.pokemongo | grep versionName | head -n1 | sed 's/ *versionName=//')
pversions=$(grep 'pogo' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')
if [[ $pinstalled != $pversions ]] ;then
  until $download /sdcard/Download/pogo.apk $url/apk/pokemongo_$arch\_$pversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/pogo.apk $url/apk/pokemongo_$arch\_$pversions.apk" >> $logfile ; logger "download pogo failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  /system/bin/pm uninstall com.nianticlabs.pokemongo
  /system/bin/pm install -r /sdcard/Download/pogo.apk
  /system/bin/rm -f /sdcard/Download/pogo.apk
  logger "pogo removed and installed, now $pversions"
else
  echo "`date +%Y-%m-%d_%T` aegis.sh: pogo version correct, proceed" >> $logfile
fi
}

send_logs(){
if [[ -z $webhook ]] ;then
  echo "`date +%Y-%m-%d_%T` aegis.sh: no webhook set in job" >> $logfile
else
  # aconf log
  curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aconf log sender\", \"content\": \"aconf.log for $origin\"}" -F "file1=@$logfile" $webhook &>/dev/null
  # monitor log
  [[ -f /sdcard/aegis_monitor.log ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aconf log sender\", \"content\": \"aegis_monitor.log for $origin\"}" -F "file1=@/sdcard/aegis_monitor.log" $webhook &>/dev/null
  # aegis log
  cp /data/local/tmp/aegis.log /sdcard/aegis.log
  curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aconf log sender\", \"content\": \"aegis.log for $origin\"}" -F "file1=@/sdcard/aegis.log" $webhook &>/dev/null
  rm /sdcard/aegis.log
  #logcat
  logcat -d > /sdcard/logcat.txt
  curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aconf log sender\", \"content\": \"logcat.txt for $origin\"}" -F "file1=@/sdcard/logcat.txt" $webhook &>/dev/null
  rm -f /sdcard/logcat.txt
  echo "`date +%Y-%m-%d_%T` aegis.sh: sending logs to discord" >> $logfile
fi
}

########## Execution

#wait on internet
until ping -c1 8.8.8.8 >/dev/null 2>/dev/null || ping -c1 1.1.1.1 >/dev/null 2>/dev/null; do
    sleep 10
done
echo "`date +%Y-%m-%d_%T` aegis.sh: internet connection available" >> $logfile

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

#download latest aegis.sh
if [[ $(basename $0) != "aegis_new.sh" ]] ;then
  mount_system_rw
  oldsh=$(head -2 /system/bin/aegis.sh | grep '# version' | awk '{ print $NF }')
  until $download /system/bin/aegis_new.sh $url/scripts/aegis.sh || { logger "download aegis.sh failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/bin/aegis_new.sh
  newsh=$(head -2 /system/bin/aegis_new.sh | grep '# version' | awk '{ print $NF }')
  if [[ $oldsh != $newsh ]] ;then
    logger "aegis.sh updated $oldsh=>$newsh, restarting script"
#   folder=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    cp /system/bin/aegis_new.sh /system/bin/aegis.sh
    mount_system_ro
    /system/bin/aegis_new.sh $@
    exit 1
  fi
fi

# download latest version file
until $download $aconf_versions $url/versions || { echo "`date +%Y-%m-%d_%T` $download $aconf_versions $url/versions" >> $logfile ; logger "download aegis versions file failed, exit script" ; exit 1; } ;do
  sleep 2
done
dos2unix $aconf_versions
echo "`date +%Y-%m-%d_%T` aegis.sh: downloaded latest versions file"  >> $logfile

# download latest mac2name file
until $download $aconf_mac2name $url/mac2name || { echo "`date +%Y-%m-%d_%T` $download $aconf_mac2name $url/mac2name" >> $logfile ; logger "download aegis mac2name file failed, skip naming" ; } ;do
  sleep 2
done
dos2unix $aconf_mac2name
echo "`date +%Y-%m-%d_%T` aegis.sh: downloaded latest mac2name file"  >> $logfile
if [[ $origin = "" ]] ;then
  mac=$(ifconfig wlan0 2>/dev/null | grep 'HWaddr' | awk '{print $5}' | cut -d ' ' -f1 && ifconfig eth0 2>/dev/null | grep 'HWaddr' | awk '{print $5}')
  origin=$(grep -m 1 $mac $aconf_mac2name | cut -d ';' -f2)
  hostname=$origin
  if [[ $origin != "" ]] ;then
    echo "`date +%Y-%m-%d_%T` aegis.sh: got origin name $origin from mac2name file"  >> $logfile
  fi
fi


#update 42aegis if needed
if [[ $(basename $0) = "aegis_new.sh" ]] ;then
  if [[ -f /system/etc/init.d/42aegis ]] ;then
    old42=$(head -2 /system/etc/init.d/42aegis | grep '# version' | awk '{ print $NF }')
    if [ $Ver42aegis != $old42 ] ;then
      mount_system_rw
      setup_initd_dir
      until $download /system/etc/init.d/42aegis $url/scripts/42aegis || { logger "download 42aegis failed, exit script" ; exit 1; } ;do
        sleep 2
      done
      chmod +x /system/etc/init.d/42aegis
      mount_system_ro
      new42=$(head -2 /system/etc/init.d/42aegis | grep '# version' | awk '{ print $NF }')
      logger "42aegis updated $old42=>$new42"
    fi
  fi
fi

#update 55aegis if needed
if [[ $(basename $0) = "aegis_new.sh" ]] ;then
  if [[ -f /system/etc/init.d/55aegis ]] ;then
    old55=$(head -2 /system/etc/init.d/55aegis | grep '# version' | awk '{ print $NF }')
    if [ $Ver55aegis != $old55 ] ;then
      mount_system_rw
      setup_initd_dir
      until $download /system/etc/init.d/55aegis $url/scripts/55aegis || { logger "download 55aegis failed, exit script" ; exit 1; } ;do
        sleep 2
      done
      chmod +x /system/etc/init.d/55aegis
      mount_system_ro
      new55=$(head -2 /system/etc/init.d/55aegis | grep '# version' | awk '{ print $NF }')
      logger "55aegis updated $old55=>$new55"
    fi
  fi
fi

#update aegis monitor if needed
if [[ $(basename $0) = "aegis_new.sh" ]] ;then
  [ -f /system/bin/aegis_monitor.sh ] && oldMonitor=$(head -2 /system/bin/aegis_monitor.sh | grep '# version' | awk '{ print $NF }') || oldMonitor="0"
  if [ $VerMonitor != $oldMonitor ] ;then
    mount_system_rw
    until $download /system/bin/aegis_monitor.sh $url/scripts/aegis_monitor.sh || { logger "download aegis_monitor.sh failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    chmod +x /system/bin/aegis_monitor.sh
    mount_system_ro
    newMonitor=$(head -2 /system/bin/aegis_monitor.sh | grep '# version' | awk '{ print $NF }')
    logger "aegis monitor updated $oldMonitor => $newMonitor"

    # restart aegis monitor
    if [[ $(grep useMonitor $aconf_versions | awk -F "=" '{ print $NF }') == "true" ]] && [ -f /system/bin/aegis_monitor.sh ] ;then
      checkMonitor=$(pgrep -f /system/bin/aegis_monitor.sh)
      if [ ! -z $checkMonitor ] ;then
        kill -9 $checkMonitor
        sleep 2
        /system/bin/aegis_monitor.sh >/dev/null 2>&1 &
        logger "aegis monitor restarted"
      fi
    fi
  fi
fi

#update AegisDetails sender if needed
if [[ $(basename $0) = "aegis_new.sh" ]] ;then
  [ -f /system/bin/AegisDetailsSender.sh ] && oldSender=$(head -2 /system/bin/AegisDetailsSender.sh | grep '# version' | awk '{ print $NF }') || oldSender="0"
  if [ $VerATVsender != $oldSender ] ;then
    mount_system_rw
    until $download /system/bin/AegisDetailsSender.sh $url/scripts/AegisDetailsSender.sh || { logger "download AegisDetailsSender.sh failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    chmod +x /system/bin/AegisDetailsSender.sh
    mount_system_ro
    newSender=$(head -2 /system/bin/AegisDetailsSender.sh | grep '# version' | awk '{ print $NF }')
    logger "AegisDetails sender updated $oldSender => $newSender"

    # restart AegisDetails sender
    if [[ $(grep useSender $aconf_versions | awk -F "=" '{ print $NF }') == "true" ]] && [ -f /system/bin/AegisDetailsSender.sh ] ;then
      checkSender=$(pgrep -f /system/bin/AegisDetailsSender.sh)
      if [ ! -z $checkSender ] ;then
        kill -9 $checkSender
        sleep 2
      fi
      /system/bin/AegisDetailsSender.sh >/dev/null 2>&1 &
      logger "AegisDetails sender (re)started"
    fi
  fi
fi


# prevent aconf causing reboot loop. Add bypass ?? <- done :)
loop_protect_enabled=$(grep 'loop_protect_enabled' $aconf_versions | awk -F "=" '{ print $NF }')
if [[ $(cat /sdcard/aconf.log | grep `date +%Y-%m-%d` | grep rebooted | grep -v "over 20 times" | wc -l) -gt 20 ]] ;then
  if [[ $loop_protect_enabled != "false" ]] ;then
    logger "device rebooted over 20 times today, aegis.sh signing out, see you tomorrow"
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

# check rgc enable/disable
check_rgc

# check aegis config file exists
if [[ -d /data/data/com.pokemod.aegis ]] && [[ ! -s $aconf ]] ;then
  install_config
  am force-stop com.pokemod.aegis
  if [ $android_version -ge 9 ]; then
    am start-foreground-service com.pokemod.aegis/com.pokemod.aegis.services.MappingService
  else
    am startservice com.pokemod.aegis/com.pokemod.aegis.services.MappingService
  fi
fi

# check 16/42mad pogo autoupdate disabled
! [[ -f /sdcard/disableautopogoupdate ]] && touch /sdcard/disableautopogoupdate

# check for webhook
if [[ $2 == https://* ]] ;then
  webhook=$2
fi

# enable aegis monitor
if [[ $(grep useMonitor $aconf_versions | awk -F "=" '{ print $NF }' | awk '{ gsub(/ /,""); print }') == "true" ]] && [ -f /system/bin/aegis_monitor.sh ] ;then
  checkMonitor=$(pgrep -f /system/bin/aegis_monitor.sh)
  if [ -z $checkMonitor ] ;then
    /system/bin/aegis_monitor.sh >/dev/null 2>&1 &
    echo "`date +%Y-%m-%d_%T` aegis.sh: aegis monitor enabled" >> $logfile
  fi
fi

# enable AegisDetails sender
if [[ $(grep useSender $aconf_versions | awk -F "=" '{ print $NF }' | awk '{ gsub(/ /,""); print }') == "true" ]] && [ -f /system/bin/AegisDetailsSender.sh ] ;then
  checkSender=$(pgrep -f /system/bin/AegisDetailsSender.sh)
  if [ -z $checkSender ] ;then
    /system/bin/AegisDetailsSender.sh >/dev/null 2>&1 &
    echo "`date +%Y-%m-%d_%T` aegis.sh: AegisDetails sender started" >> $logfile
  fi
fi

# check aegis running
aegis_check=$(ps | grep com.pokemod.aegis:mapping | awk '{print $9}')
if [[ -z $aegis_check ]] && [[ -f /data/local/tmp/aegis_config.json ]] ;then
  logger "aegis not running at execution of aegis.sh, starting it"
  if [ $android_version -ge 9 ]; then
    am start-foreground-service com.pokemod.aegis/com.pokemod.aegis.services.MappingService
  else
    am startservice com.pokemod.aegis/com.pokemod.aegis.services.MappingService
  fi
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
    am force-stop com.pokemod.aegis
    am force-stop com.nianticlabs.pokemongo
    /sbin/magisk --install-module /sdcard/Download/PIF_module.zip
    logger "Updated PIF module from $instPIFv to $versionsPIFv"
    reboot=1
  else
    echo "`date +%Y-%m-%d_%T` aegis.sh: PIF module correct, proceed" >> $logfile
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
    echo "`date +%Y-%m-%d_%T` aegis.sh: FingerPrint correct, proceed" >> $logfile
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
    echo "`date +%Y-%m-%d_%T` aegis.sh: CustomJob Up2Date, proceed" >> $logfile
  fi
fi


for i in "$@" ;do
 case "$i" in
 -ia) install_aegis ;;
 -ic) install_config ;;
 -ua) update_all ;;
 -uac) update_aegis_config ;;
 -dp) downgrade_pogo;;
 -cr) check_rgc;;
 -sl) send_logs;;
# consider adding: downgrade aegis, update donwload link
 esac
done


(( $reboot )) && reboot_device
exit