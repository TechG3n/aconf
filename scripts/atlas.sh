#!/system/bin/sh
# version 2.1.25

#Version checks
Ver42atlas="1.5"
Ver55atlas="1.0"
VerMonitor="3.2.6"
VerATVsender="1.7.9"

#Create logfile
if [ ! -e /sdcard/aconf.log ] ;then
    touch /sdcard/aconf.log
fi

logfile="/sdcard/aconf.log"
[[ -d /data/data/com.mad.pogodroid ]] && puser=$(ls -la /data/data/com.mad.pogodroid/ | head -n2 | tail -n1 | awk '{print $3}')
pdconf="/data/data/com.mad.pogodroid/shared_prefs/com.mad.pogodroid_preferences.xml"
[[ -d /data/data/de.grennith.rgc.remotegpscontroller ]] && ruser=$(ls -la /data/data/de.grennith.rgc.remotegpscontroller/ |head -n2 | tail -n1 | awk '{print $3}')
rgcconf="/data/data/de.grennith.rgc.remotegpscontroller/shared_prefs/de.grennith.rgc.remotegpscontroller_preferences.xml"
aconf="/data/local/tmp/atlas_config.json"
aconf_versions="/data/local/aconf_versions"
[[ -f /data/local/aconf_download ]] && url=$(grep url /data/local/aconf_download | awk -F "=" '{ print $NF }')
[[ -f /data/local/aconf_download ]] && aconf_user=$(grep authUser /data/local/aconf_download | awk -F "=" '{ print $NF }')
[[ -f /data/local/aconf_download ]] && aconf_pass=$(grep authPass /data/local/aconf_download | awk -F "=" '{ print $NF }')
discord_webhook=$(grep 'discord_webhook' $aconf_versions | awk -F "=" '{ print $NF }' | sed -e 's/^"//' -e 's/"$//')
if [[ -z $discord_webhook ]] ;then
  discord_webhook=$(grep discord_webhook /data/local/aconf_download | awk -F "=" '{ print $NF }' | sed -e 's/^"//' -e 's/"$//')
fi

if [[ -f /data/local/tmp/atlas_config.json ]] ;then
#  origin=$(grep -w 'deviceName' $aconf | awk -F "\"" '{ print $4 }')
  origin=$(cat $aconf | tr , '\n' | grep -w 'deviceName' | awk -F "\"" '{ print $4 }')
else
  if [[ -f /data/data/de.grennith.rgc.remotegpscontroller/shared_prefs/de.grennith.rgc.remotegpscontroller_preferences.xml ]] ;then
    origin=$(grep -w 'websocket_origin' $rgcconf | sed -e 's/    <string name="websocket_origin">\(.*\)<\/string>/\1/')
  else
    echo "`date +%Y-%m-%d_%T` atlas.sh: cannot find origin, that can't be right" >> $logfile
  fi
fi

# stderr to logfile
exec 2>> $logfile

# add atlas.sh command to log
echo "" >> $logfile
echo "`date +%Y-%m-%d_%T` atlas.sh: executing $(basename $0) $@" >> $logfile
# echo "`date +%Y-%m-%d_%T` download folder set to $url, user is $aconf_user with pass $aconf_pass" >> $logfile


########## Functions

# logger
logger() {
if [[ ! -z $discord_webhook ]] ;then
  echo "`date +%Y-%m-%d_%T` atlas.sh: $1" >> $logfile
  if [[ -z $origin ]] ;then
    curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas.sh\", \"content\": \" $1 \"}"  $discord_webhook &>/dev/null
  else
    curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"atlas.sh\", \"content\": \" $origin: $1 \"}"  $discord_webhook &>/dev/null
  fi
else
  echo "`date +%Y-%m-%d_%T` atlas.sh: $1" >> $logfile
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

install_atlas(){

# install 55atlas if 42atlas does not exist
mount -o remount,rw /system
mount -o remount,rw /system/etc/init.d
if [ ! -f /system/etc/init.d/42atlas ] ;then
  until $download /system/etc/init.d/55atlas $url/scripts/55atlas || { logger "download 55atlas failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/etc/init.d/55atlas
  logger "55atlas installed"
fi

# install atlas monitor
  until $download /system/bin/atlas_monitor.sh $url/scripts/atlas_monitor.sh || { logger "download atlas_monitor.sh failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/bin/atlas_monitor.sh
  logger "atlas monitor installed"

# install ATVdetails sender
  until $download /system/bin/ATVdetailsSender.sh $url/scripts/ATVdetailsSender.sh || { logger "download ATVdetailsSender.sh failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/bin/ATVdetailsSender.sh
  logger "atvdetails sender installed"

mount -o remount,ro /system
mount -o remount,ro /system/etc/init.d


# get version
aversions=$(grep 'atlas' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')

# download atlas
/system/bin/rm -f /sdcard/Download/atlas.apk
until $download /sdcard/Download/atlas.apk $url/apk/PokemodAtlas-Public-$aversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/atlas.apk $url/apk/PokemodAtlas-Public-$aversions.apk" >> $logfile ; logger "download atlas failed, exit script" ; exit 1; } ;do
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

# Install atlas
/system/bin/pm install -r /sdcard/Download/atlas.apk
/system/bin/rm -f /sdcard/Download/atlas.apk
logger "atlas installed"

# Grant su access + settings
auid="$(dumpsys package com.pokemod.atlas | grep userId | awk -F'=' '{print $2}')"
magisk --sqlite "DELETE from policies WHERE package_name='com.pokemod.atlas'"
magisk --sqlite "INSERT INTO policies (uid,package_name,policy,until,logging,notification) VALUES($auid,'com.pokemod.atlas',2,0,1,0)"
pm grant com.pokemod.atlas android.permission.READ_EXTERNAL_STORAGE
pm grant com.pokemod.atlas android.permission.WRITE_EXTERNAL_STORAGE
logger "atlas granted su and settings set"

# download atlas config file and adjust orgin to rgc setting
install_config

# check pogo version else remove+install
downgrade_pogo

# check if rgc is to be enabled or disabled
check_rgc

# start atlas
am startservice com.pokemod.atlas/com.pokemod.atlas.services.MappingService
sleep 15

# Set for reboot device
reboot=1

## Send final webhook
# discord_config_wh=$(grep 'discord_webhook' $aconf_versions | awk -F "=" '{ print $NF }')
ip=$(ifconfig eth0 |grep 'inet addr' |cut -d ':' -f2 |cut -d ' ' -f1)
logger "new atlas device configured. IP: $ip"

}

install_config(){
until $download /data/local/tmp/atlas_config.json $url/atlas_config.json || { echo "`date +%Y-%m-%d_%T` $download /data/local/tmp/atlas_config.json $url/atlas_config.json" >> $logfile ; logger "download atlas config file failed, exit script" ; exit 1; } ;do
  sleep 2
done
sed -i 's,dummy,'$origin',g' $aconf
logger "atlas config installed"
}

update_atlas_config(){
if [[ -z $origin ]] ;then
  logger "will not replace atlas config file without deviceName being set"
else
  until $download /data/local/tmp/atlas_config.json $url/atlas_config.json || { echo "`date +%Y-%m-%d_%T` $download /data/local/tmp/atlas_config.json $url/atlas_config.json" >> $logfile ; logger "download atlas config file failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  sed -i 's,dummy,'$origin',g' $aconf
  am force-stop com.pokemod.atlas && am startservice com.pokemod.atlas/com.pokemod.atlas.services.MappingService
  logger "atlas config updated and atlas restarted"
fi
}

update_all(){
pinstalled=$(dumpsys package com.nianticlabs.pokemongo | grep versionName | head -n1 | sed 's/ *versionName=//')
pversions=$(grep 'pogo' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')
ainstalled=$(dumpsys package com.pokemod.atlas | grep versionName | head -n1 | sed 's/ *versionName=//')
aversions=$(grep 'atlas' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')

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
 echo "`date +%Y-%m-%d_%T` atlas.sh: pogo already on correct version" >> $logfile
fi

if [ v$ainstalled != $aversions ] ;then
  logger "new atlas version detected, $ainstalled=>$aversions"
  /system/bin/rm -f /sdcard/Download/atlas.apk
  until $download /sdcard/Download/atlas.apk $url/apk/PokemodAtlas-Public-$aversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/atlas.apk $url/apk/PokemodAtlas-Public-$aversions.apk" >> $logfile ; logger "download atlas failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  # set atlas to be installed
  atlas_install="install"
else
 atlas_install="skip"
 echo "`date +%Y-%m-%d_%T` atlas.sh: atlas already on correct version" >> $logfile
fi

if [ ! -z "$atlas_install" ] && [ ! -z "$pogo_install" ] ;then
  echo "`date +%Y-%m-%d_%T` atlas.sh: all updates checked and downloaded if needed" >> $logfile
  if [ "$atlas_install" = "install" ] ;then
    Logger "Updating atlas"
    # install atlas
    /system/bin/pm install -r /sdcard/Download/atlas.apk || { logger "install atlas failed, downgrade perhaps? Exit script" ; exit 1; }
    /system/bin/rm -f /sdcard/Download/atlas.apk
    reboot=1
  fi
  if [ "$pogo_install" = "install" ] ;then
    logger "updating pogo"
    # install pogo
    /system/bin/pm install -r /sdcard/Download/pogo.apk || { logger "install pogo failed, downgrade perhaps? Exit script" ; exit 1; }
    /system/bin/rm -f /sdcard/Download/pogo.apk
    reboot=1
  fi
  if [ "$atlas_install" != "install" ] && [ "$pogo_install" != "install" ] ; then
    echo "`date +%Y-%m-%d_%T` atlas.sh: updates checked, nothing to install" >> $logfile
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
  echo "`date +%Y-%m-%d_%T` atlas.sh: pogo version correct, proceed" >> $logfile
fi
}

send_logs(){
if [[ -z $webhook ]] ;then
  echo "`date +%Y-%m-%d_%T` atlas.sh: no webhook set in job" >> $logfile
else
  # aconf log
  curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aconf log sender\", \"content\": \"aconf.log for $origin\"}" -F "file1=@$logfile" $webhook &>/dev/null
  # monitor log
  [[ -f /sdcard/atlas_monitor.log ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aconf log sender\", \"content\": \"atlas_monitor.log for $origin\"}" -F "file1=@/sdcard/atlas_monitor.log" $webhook &>/dev/null
  # atlas log
  cp /data/local/tmp/atlas.log /sdcard/atlas.log
  curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aconf log sender\", \"content\": \"atlas.log for $origin\"}" -F "file1=@/sdcard/atlas.log" $webhook &>/dev/null
  rm /sdcard/atlas.log
  #logcat
  logcat -d > /sdcard/logcat.txt
  curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aconf log sender\", \"content\": \"logcat.txt for $origin\"}" -F "file1=@/sdcard/logcat.txt" $webhook &>/dev/null
  rm -f /sdcard/logcat.txt
  echo "`date +%Y-%m-%d_%T` atlas.sh: sending logs to discord" >> $logfile
fi
}

########## Execution

#wait on internet
until ping -c1 8.8.8.8 >/dev/null 2>/dev/null || ping -c1 1.1.1.1 >/dev/null 2>/dev/null; do
    sleep 10
done
echo "`date +%Y-%m-%d_%T` atlas.sh: internet connection available" >> $logfile

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

#download latest atlas.sh
if [[ $(basename $0) != "atlas_new.sh" ]] ;then
  mount -o remount,rw /system
  oldsh=$(head -2 /system/bin/atlas.sh | grep '# version' | awk '{ print $NF }')
  until $download /system/bin/atlas_new.sh $url/scripts/atlas.sh || { logger "download atlas.sh failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/bin/atlas_new.sh
  newsh=$(head -2 /system/bin/atlas_new.sh | grep '# version' | awk '{ print $NF }')
  if [[ $oldsh != $newsh ]] ;then
    logger "atlas.sh updated $oldsh=>$newsh, restarting script"
#   folder=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    cp /system/bin/atlas_new.sh /system/bin/atlas.sh
    mount -o remount,ro /system
    /system/bin/atlas_new.sh $@
    exit 1
  fi
fi

# download latest version file
until $download $aconf_versions $url/versions || { echo "`date +%Y-%m-%d_%T` $download $aconf_versions $url/versions" >> $logfile ; logger "download atlas versions file failed, exit script" ; exit 1; } ;do
  sleep 2
done
dos2unix $aconf_versions
echo "`date +%Y-%m-%d_%T` atlas.sh: downloaded latest versions file"  >> $logfile

#update 42atlas if needed
if [[ $(basename $0) = "atlas_new.sh" ]] ;then
  if [[ -f /system/etc/init.d/42atlas ]] ;then
    old42=$(head -2 /system/etc/init.d/42atlas | grep '# version' | awk '{ print $NF }')
    if [ $Ver42atlas != $old42 ] ;then
      mount -o remount,rw /system
      mount -o remount,rw /system/etc/init.d
      until $download /system/etc/init.d/42atlas $url/scripts/42atlas || { logger "download 42atlas failed, exit script" ; exit 1; } ;do
        sleep 2
      done
      chmod +x /system/etc/init.d/42atlas
      mount -o remount,ro /system
      mount -o remount,ro /system/etc/init.d
      new42=$(head -2 /system/etc/init.d/42atlas | grep '# version' | awk '{ print $NF }')
      logger "42atlas updated $old42=>$new42"
    fi
  fi
fi

#update 55atlas if needed
if [[ $(basename $0) = "atlas_new.sh" ]] ;then
  if [[ -f /system/etc/init.d/55atlas ]] ;then
    old55=$(head -2 /system/etc/init.d/55atlas | grep '# version' | awk '{ print $NF }')
    if [ $Ver55atlas != $old55 ] ;then
      mount -o remount,rw /system
      mount -o remount,rw /system/etc/init.d
      until $download /system/etc/init.d/55atlas $url/scripts/55atlas || { logger "download 55atlas failed, exit script" ; exit 1; } ;do
        sleep 2
      done
      chmod +x /system/etc/init.d/55atlas
      mount -o remount,ro /system
      mount -o remount,ro /system/etc/init.d
      new55=$(head -2 /system/etc/init.d/55atlas | grep '# version' | awk '{ print $NF }')
      logger "55atlas updated $old55=>$new55"
    fi
  fi
fi

#update atlas monitor if needed
if [[ $(basename $0) = "atlas_new.sh" ]] ;then
  [ -f /system/bin/atlas_monitor.sh ] && oldMonitor=$(head -2 /system/bin/atlas_monitor.sh | grep '# version' | awk '{ print $NF }') || oldMonitor="0"
  if [ $VerMonitor != $oldMonitor ] ;then
    mount -o remount,rw /system
    until $download /system/bin/atlas_monitor.sh $url/scripts/atlas_monitor.sh || { logger "download atlas_monitor.sh failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    chmod +x /system/bin/atlas_monitor.sh
    mount -o remount,ro /system
    newMonitor=$(head -2 /system/bin/atlas_monitor.sh | grep '# version' | awk '{ print $NF }')
    logger "atlas monitor updated $oldMonitor => $newMonitor"

    # restart atlas monitor
    if [[ $(grep useMonitor $aconf_versions | awk -F "=" '{ print $NF }') == "true" ]] && [ -f /system/bin/atlas_monitor.sh ] ;then
      checkMonitor=$(pgrep -f /system/bin/atlas_monitor.sh)
      if [ ! -z $checkMonitor ] ;then
        kill -9 $checkMonitor
        sleep 2
        /system/bin/atlas_monitor.sh >/dev/null 2>&1 &
        logger "atlas monitor restarted"
      fi
    fi
  fi
fi

#update atvdetails sender if needed
if [[ $(basename $0) = "atlas_new.sh" ]] ;then
  [ -f /system/bin/ATVdetailsSender.sh ] && oldSender=$(head -2 /system/bin/ATVdetailsSender.sh | grep '# version' | awk '{ print $NF }') || oldSender="0"
  if [ $VerATVsender != $oldSender ] ;then
    mount -o remount,rw /system
    until $download /system/bin/ATVdetailsSender.sh $url/scripts/ATVdetailsSender.sh || { logger "download ATVdetailsSender.sh failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    chmod +x /system/bin/ATVdetailsSender.sh
    mount -o remount,ro /system
    newSender=$(head -2 /system/bin/ATVdetailsSender.sh | grep '# version' | awk '{ print $NF }')
    logger "atvdetails sender updated $oldSender => $newSender"

    # restart ATVdetails sender
    if [[ $(grep useSender $aconf_versions | awk -F "=" '{ print $NF }') == "true" ]] && [ -f /system/bin/ATVdetailsSender.sh ] ;then
      checkSender=$(pgrep -f /system/bin/ATVdetailsSender.sh)
      if [ ! -z $checkSender ] ;then
        kill -9 $checkSender
        sleep 2
      fi
      /system/bin/ATVdetailsSender.sh >/dev/null 2>&1 &
      logger "atvdetails sender (re)started"
    fi
  fi
fi


# prevent aconf causing reboot loop. Add bypass ?? <- done :)
if [[ $(cat /sdcard/aconf.log | grep `date +%Y-%m-%d` | grep rebooted | wc -l) -gt 20 ]] && [[ $loop_protect_enabled != "false" ]] ;then
  logger "device rebooted over 20 times today, atlas.sh signing out, see you tomorrow"
  exit 1
fi

# set hostname = origin, wait till next reboot for it to take effect
if [[ $origin != "" ]] ;then
  if [ $(cat /system/build.prop | grep net.hostname | wc -l) = 0 ]; then
    mount -o remount,rw /system
    logger "no hostname set, setting it to $origin"
    echo "net.hostname=$origin" >> /system/build.prop
    mount -o remount,ro /system
  else
    hostname=$(grep net.hostname /system/build.prop | awk 'BEGIN { FS = "=" } ; { print $2 }')
    if [[ $hostname != $origin ]] ;then
      mount -o remount,rw /system
      logger "changing hostname, from $hostname to $origin"
      sed -i -e "s/^net.hostname=.*/net.hostname=$origin/g" /system/build.prop
      mount -o remount,ro /system
    fi
  fi
fi

# check rgc enable/disable
check_rgc

# check atlas config file exists
if [[ -d /data/data/com.pokemod.atlas ]] && [[ ! -s $aconf ]] ;then
install_config
am force-stop com.pokemod.atlas
am startservice com.pokemod.atlas/com.pokemod.atlas.services.MappingService
fi

# check 16/42mad pogo autoupdate disabled
! [[ -f /sdcard/disableautopogoupdate ]] && touch /sdcard/disableautopogoupdate

# check for webhook
if [[ $2 == https://* ]] ;then
  webhook=$2
fi

# enable atlas monitor
if [[ $(grep useMonitor $aconf_versions | awk -F "=" '{ print $NF }' | awk '{ gsub(/ /,""); print }') == "true" ]] && [ -f /system/bin/atlas_monitor.sh ] ;then
  checkMonitor=$(pgrep -f /system/bin/atlas_monitor.sh)
  if [ -z $checkMonitor ] ;then
    /system/bin/atlas_monitor.sh >/dev/null 2>&1 &
    echo "`date +%Y-%m-%d_%T` atlas.sh: atlas monitor enabled" >> $logfile
  fi
fi

# enable atvdetails sender
if [[ $(grep useSender $aconf_versions | awk -F "=" '{ print $NF }' | awk '{ gsub(/ /,""); print }') == "true" ]] && [ -f /system/bin/ATVdetailsSender.sh ] ;then
  checkSender=$(pgrep -f /system/bin/ATVdetailsSender.sh)
  if [ -z $checkSender ] ;then
    /system/bin/ATVdetailsSender.sh >/dev/null 2>&1 &
    echo "`date +%Y-%m-%d_%T` atlas.sh: atvdetails sender started" >> $logfile
  fi
fi

# check atlas running
atlas_check=$(ps | grep com.pokemod.atlas:mapping | awk '{print $9}')
if [[ -z $atlas_check ]] && [[ -f /data/local/tmp/atlas_config.json ]] ;then
  am startservice com.pokemod.atlas/com.pokemod.atlas.services.MappingService
  logger "atlas not running at execution of atlas.sh, starting it"
fi

# check if playstore is enabled
if [ "$(pm list packages -d com.android.vending)" = "package:com.android.vending" ] ;then
  logger "Enabling Play Store"
  pm enable com.android.vending
fi

# disable PlayIntegrity APK verification
pintegrity=$(settings get global package_verifier_user_consent)
if [[ $play_integrity != "false" ]] && [[ $pintegrity == 1 ]]; then
  settings put global package_verifier_user_consent -1
  logger "disabled PlayIntegrity APK verification"
fi  


for i in "$@" ;do
 case "$i" in
 -ia) install_atlas ;;
 -ic) install_config ;;
 -ua) update_all ;;
 -uac) update_atlas_config ;;
 -dp) downgrade_pogo;;
 -cr) check_rgc;;
 -sl) send_logs;;
# consider adding: downgrade atlas, update donwload link
 esac
done


(( $reboot )) && reboot_device
exit
