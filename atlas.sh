#!/system/bin/sh
# version 1.4.0

#Version checks
Ver55atlas="1.0"
VerMonitor="3.1.7"
VerATVsender="1.0"

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
[[ -f /data/local/aconf_download ]] && aconf_download=$(grep url /data/local/aconf_download | awk -F "=" '{ print $NF }')
[[ -f /data/local/aconf_download ]] && aconf_user=$(grep authUser /data/local/aconf_download | awk -F "=" '{ print $NF }')
[[ -f /data/local/aconf_download ]] && aconf_pass=$(grep authPass /data/local/aconf_download | awk -F "=" '{ print $NF }')
if [[ -f /data/local/tmp/atlas_config.json ]] ;then
#  origin=$(grep -w 'deviceName' $aconf | awk -F "\"" '{ print $4 }')
  origin=$(cat $aconf | tr , '\n' | grep -w 'deviceName' | awk -F "\"" '{ print $4 }')
else
  if [[ -f /data/data/de.grennith.rgc.remotegpscontroller/shared_prefs/de.grennith.rgc.remotegpscontroller_preferences.xml ]] ;then
    origin=$(grep -w 'websocket_origin' $rgcconf | sed -e 's/    <string name="websocket_origin">\(.*\)<\/string>/\1/')
  else
    echo "`date +%Y-%m-%d_%T` Cannot find origin, that can't be right" >> $logfile
  fi
fi

# stderr to logfile
exec 2>> $logfile

# add atlas.sh command to log
echo "" >> $logfile
echo "`date +%Y-%m-%d_%T` ## Executing $(basename $0) $@" >> $logfile
# echo "`date +%Y-%m-%d_%T` download folder set to $aconf_download, user is $aconf_user with pass $aconf_pass" >> $logfile


########## Functions

reboot_device(){
echo "`date +%Y-%m-%d_%T` Reboot device" >> $logfile
sleep 2
/system/bin/reboot
}

case "$(uname -m)" in
 aarch64) arch="arm64-v8a";;
 armv8l)  arch="armeabi-v7a";;
esac

install_atlas(){

# install 55atlas
mount -o remount,rw /system
if [ -f /sdcard/useAconfDevelop ] ;then
  until /system/bin/curl -s -k -L --fail --show-error -o /system/etc/init.d/55atlas https://raw.githubusercontent.com/dkmur/aconf/develop/55atlas || { echo "`date +%Y-%m-%d_%T` Download 55atlas failed, exit script" >> $logfile ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/etc/init.d/55atlas
  echo "`date +%Y-%m-%d_%T` 55atlas installed, from develop" >> $logfile
else
  until /system/bin/curl -s -k -L --fail --show-error -o /system/etc/init.d/55atlas https://raw.githubusercontent.com/dkmur/aconf/master/55atlas || { echo "`date +%Y-%m-%d_%T` Download 55atlas failed, exit script" >> $logfile ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/etc/init.d/55atlas
  echo "`date +%Y-%m-%d_%T` 55atlas installed, from master" >> $logfile
fi

# install atlas monitor
if [ -f /sdcard/useAconfDevelop ] ;then
  until /system/bin/curl -s -k -L --fail --show-error -o /system/bin/atlas_monitor.sh https://raw.githubusercontent.com/dkmur/aconf/develop/atlas_monitor.sh || { echo "`date +%Y-%m-%d_%T` Download atlas_monitor failed, exit script" >> $logfile ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/bin/atlas_monitor.sh
  echo "`date +%Y-%m-%d_%T` Atlas monitor installed, from develop" >> $logfile
else
  until /system/bin/curl -s -k -L --fail --show-error -o /system/bin/atlas_monitor.sh https://raw.githubusercontent.com/dkmur/aconf/master/atlas_monitor.sh || { echo "`date +%Y-%m-%d_%T` Download atlas_monitor failed, exit script" >> $logfile ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/bin/atlas_monitor.sh
  echo "`date +%Y-%m-%d_%T` Atlas monitor installed, from master" >> $logfile
fi

# install ATVdetails sender
if [ -f /sdcard/useAconfDevelop ] ;then
  until /system/bin/curl -s -k -L --fail --show-error -o /system/bin/ATVdetailsSender.sh https://raw.githubusercontent.com/dkmur/aconf/develop/ATVdetailsSender.sh || { echo "`date +%Y-%m-%d_%T` Download ATVdetailsSender failed, exit script" >> $logfile ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/bin/ATVdetailsSender.sh
  echo "`date +%Y-%m-%d_%T` ATVdetails sender installed, from develop" >> $logfile
else
  until /system/bin/curl -s -k -L --fail --show-error -o /system/bin/ATVdetailsSender.sh https://raw.githubusercontent.com/dkmur/aconf/master/ATVdetailsSender.sh || { echo "`date +%Y-%m-%d_%T` Download ATVdetailsSender failed, exit script" >> $logfile ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/bin/ATVdetailsSender.sh
  echo "`date +%Y-%m-%d_%T` ATVdetails sender installed, from master" >> $logfile
fi
mount -o remount,ro /system


# get version
aversions=$(grep 'atlas' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')

# download atlas
/system/bin/rm -f /sdcard/Download/atlas.apk
until $download /sdcard/Download/atlas.apk $aconf_download/PokemodAtlas-Public-$aversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/atlas.apk $aconf_download/PokemodAtlas-Public-$aversions.apk" >> $logfile ; echo "`date +%Y-%m-%d_%T` Download atlas failed, exit script" >> $logfile ; exit 1; } ;do
  sleep 2
done

# pogodroid disable full daemon + stop pogodroid
if [ -f "$pdconf" ] ;then
  sed -i 's,\"full_daemon\" value=\"true\",\"full_daemon\" value=\"false\",g' $pdconf
  chmod 660 $pdconf
  chown $puser:$puser $pdconf
  am force-stop com.mad.pogodroid
  echo "`date +%Y-%m-%d_%T` pogodroid disabled" >> $logfile
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
echo "`date +%Y-%m-%d_%T` atlas installed" >> $logfile

# Grant su access + settings
auid="$(dumpsys package com.pokemod.atlas | grep userId | awk -F'=' '{print $2}')"
magisk --sqlite "DELETE from policies WHERE package_name='com.pokemod.atlas'"
magisk --sqlite "INSERT INTO policies (uid,package_name,policy,until,logging,notification) VALUES($auid,'com.pokemod.atlas',2,0,1,0)"
pm grant com.pokemod.atlas android.permission.READ_EXTERNAL_STORAGE
pm grant com.pokemod.atlas android.permission.WRITE_EXTERNAL_STORAGE
echo "`date +%Y-%m-%d_%T` atlas granted su and settings set" >> $logfile

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

## Send webhook
discord_config_wh=$(grep 'discord_webhook' $aconf_versions | awk -F "=" '{ print $NF }')
ip=$(ifconfig eth0 |grep 'inet addr' |cut -d ':' -f2 |cut -d ' ' -f1)

if [[ ! -z $discord_config_wh ]] ;then
  curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"Aconf new device\", \"content\": \"New atlas device configured. Origin: $origin , IP: $ip \"}"  $discord_config_wh &>/dev/null
  echo "`date +%Y-%m-%d_%T` Send new device webhook to discord" >> $logfile
fi
}

install_config(){
until $download /data/local/tmp/atlas_config.json $aconf_download/atlas_config.json || { echo "`date +%Y-%m-%d_%T` $download /data/local/tmp/atlas_config.json $aconf_download/atlas_config.json" >> $logfile ; echo "`date +%Y-%m-%d_%T` Download atlas config file failed, exit script" >> $logfile ; exit 1; } ;do
  sleep 2
done
sed -i 's,dummy,'$origin',g' $aconf
echo "`date +%Y-%m-%d_%T` atlas config installed, deviceName $origin"  >> $logfile
}

update_all(){
pinstalled=$(dumpsys package com.nianticlabs.pokemongo | grep versionName | head -n1 | sed 's/ *versionName=//')
pversions=$(grep 'pogo' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')
ainstalled=$(dumpsys package com.pokemod.atlas | grep versionName | head -n1 | sed 's/ *versionName=//')
aversions=$(grep 'atlas' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')

if [[ $pinstalled != $pversions ]] ;then
  echo "`date +%Y-%m-%d_%T` New pogo version detected, $pinstalled=>$pversions" >> $logfile
  /system/bin/rm -f /sdcard/Download/pogo.apk
  until $download /sdcard/Download/pogo.apk $aconf_download/pokemongo_$arch\_$pversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/pogo.apk $aconf_download/pokemongo_$arch\_$pversions.apk" >> $logfile ; echo "`date +%Y-%m-%d_%T` Download pogo failed, exit script" >> $logfile ; exit 1; } ;do
    sleep 2
  done
  # set pogo to be installed
  pogo_install="install"
else
 pogo_install="skip"
 echo "`date +%Y-%m-%d_%T` PoGo already on correct version" >> $logfile
fi

if [ v$ainstalled != $aversions ] ;then
  echo "`date +%Y-%m-%d_%T` New atlas version detected, $ainstalled=>$aversions" >> $logfile
  /system/bin/rm -f /sdcard/Download/atlas.apk
  until $download /sdcard/Download/atlas.apk $aconf_download/PokemodAtlas-Public-$aversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/atlas.apk $aconf_download/PokemodAtlas-Public-$aversions.apk" >> $logfile ; echo "`date +%Y-%m-%d_%T` Download atlas failed, exit script" >> $logfile ; exit 1; } ;do
    sleep 2
  done
  # set atlas to be installed
  atlas_install="install"
else
 atlas_install="skip"
 echo "`date +%Y-%m-%d_%T` atlas already on correct version" >> $logfile
fi

if [ ! -z "$atlas_install" ] && [ ! -z "$pogo_install" ] ;then
  echo "`date +%Y-%m-%d_%T` All updates checked and downloaded if needed" >> $logfile
  if [ "$atlas_install" = "install" ] ;then
    echo "`date +%Y-%m-%d_%T` Updating atlas" >> $logfile
    # install atlas
    /system/bin/pm install -r /sdcard/Download/atlas.apk || { echo "`date +%Y-%m-%d_%T` Install atlas failed, downgrade perhaps? Exit script" >> $logfile ; exit 1; }
    /system/bin/rm -f /sdcard/Download/atlas.apk
    reboot=1
  fi
  if [ "$pogo_install" = "install" ] ;then
    echo "`date +%Y-%m-%d_%T` Updating pogo" >> $logfile
    # install pogo
    /system/bin/pm install -r /sdcard/Download/pogo.apk || { echo "`date +%Y-%m-%d_%T` Install pogo failed, downgrade perhaps? Exit script" >> $logfile ; exit 1; }
    /system/bin/rm -f /sdcard/Download/pogo.apk
    reboot=1
  fi
  if [ "$atlas_install" != "install" ] && [ "$pogo_install" != "install" ] ; then
    echo "`date +%Y-%m-%d_%T` Updates checked, nothing to install" >> $logfile
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
    echo "`date +%Y-%m-%d_%T` rgc disabled" >> $logfile
  fi
  if [[ $rgccheck == "on" ]] && [[ $rgcstatus == "false" ]] ;then
    # enable rgc
    sed -i 's,\"autostart_services\" value=\"false\",\"autostart_services\" value=\"true\",g' $rgcconf
    sed -i 's,\"boot_startup\" value=\"false\",\"boot_startup\" value=\"true\",g' $rgcconf
    chmod 660 $rgcconf
    chown $ruser:$ruser $rgcconf
    # start rgc
    monkey -p de.grennith.rgc.remotegpscontroller 1
    echo "`date +%Y-%m-%d_%T` rgc enabled and started" >> $logfile
  fi
fi
}

downgrade_pogo(){
pinstalled=$(dumpsys package com.nianticlabs.pokemongo | grep versionName | head -n1 | sed 's/ *versionName=//')
pversions=$(grep 'pogo' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')
if [[ $pinstalled != $pversions ]] ;then
  until $download /sdcard/Download/pogo.apk $aconf_download/pokemongo_$arch\_$pversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/pogo.apk $aconf_download/pokemongo_$arch\_$pversions.apk" >> $logfile ; echo "`date +%Y-%m-%d_%T` Download pogo failed, exit script" >> $logfile ; exit 1; } ;do
    sleep 2
  done
  /system/bin/pm uninstall com.nianticlabs.pokemongo
  /system/bin/pm install -r /sdcard/Download/pogo.apk
  /system/bin/rm -f /sdcard/Download/pogo.apk
  echo "`date +%Y-%m-%d_%T` PoGo removed and installed, now $pversions" >> $logfile
else
  echo "`date +%Y-%m-%d_%T` pogo version correct, proceed" >> $logfile
fi
}

send_logs(){
if [[ -z $webhook ]] ;then
  echo "`date +%Y-%m-%d_%T` No webhook set in job" >> $logfile
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
  echo "`date +%Y-%m-%d_%T` Sending logs to discord" >> $logfile
fi
}

########## Execution

#wait on internet
until ping -c1 8.8.8.8 >/dev/null 2>/dev/null || ping -c1 1.1.1.1 >/dev/null 2>/dev/null; do
    sleep 10
done
echo "`date +%Y-%m-%d_%T` Internet connection available" >> $logfile


#download latest atlas.sh
if [[ $(basename $0) != "atlas_new.sh" ]] ;then
  mount -o remount,rw /system
  oldsh=$(head -2 /system/bin/atlas.sh | grep '# version' | awk '{ print $NF }')
  if [ -f /sdcard/useAconfDevelop ] ;then
    until /system/bin/curl -s -k -L --fail --show-error -o /system/bin/atlas_new.sh https://raw.githubusercontent.com/dkmur/aconf/develop/atlas.sh || { echo "`date +%Y-%m-%d_%T` Download atlas.sh failed, exit script" >> $logfile ; exit 1; } ;do
      sleep 2
    done
    chmod +x /system/bin/atlas_new.sh
  else
    until /system/bin/curl -s -k -L --fail --show-error -o /system/bin/atlas_new.sh https://raw.githubusercontent.com/dkmur/aconf/master/atlas.sh || { echo "`date +%Y-%m-%d_%T` Download atlas.sh failed, exit script" >> $logfile ; exit 1; } ;do
      sleep 2
    done
    chmod +x /system/bin/atlas_new.sh
  fi
  newsh=$(head -2 /system/bin/atlas_new.sh | grep '# version' | awk '{ print $NF }')
  if [[ $oldsh != $newsh ]] ;then
    echo "`date +%Y-%m-%d_%T` atlas.sh $oldsh=>$newsh, restarting script" >> $logfile
#   folder=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    cp /system/bin/atlas_new.sh /system/bin/atlas.sh
    mount -o remount,ro /system
    /system/bin/atlas_new.sh $@
    exit 1
  fi
fi

# verify download credential file and set download
if [[ ! -f /data/local/aconf_download ]] ;then
  echo "`date +%Y-%m-%d_%T` File /data/local/aconf_download not found, exit script" >> $logfile && exit 1
else
  if [[ $aconf_user == "" ]] ;then
    download="/system/bin/curl -s -k -L --fail --show-error -o"
  else
    download="/system/bin/curl -s -k -L --fail --show-error --user $aconf_user:$aconf_pass -o"
  fi
fi

# download latest version file
until $download $aconf_versions $aconf_download/versions || { echo "`date +%Y-%m-%d_%T` $download $aconf_versions $aconf_download/versions" >> $logfile ; echo "`date +%Y-%m-%d_%T` Download atlas versions file failed, exit script" >> $logfile ; exit 1; } ;do
  sleep 2
done
dos2unix $aconf_versions
echo "`date +%Y-%m-%d_%T` Downloaded latest versions file"  >> $logfile

#update 55atlas if needed
if [[ $(basename $0) = "atlas_new.sh" ]] ;then
  old55=$(head -2 /system/etc/init.d/55atlas | grep '# version' | awk '{ print $NF }')
  if [ $Ver55atlas != $old55 ] ;then
    mount -o remount,rw /system
    if [ -f /sdcard/useAconfDevelop ] ;then
      until /system/bin/curl -s -k -L --fail --show-error -o /system/etc/init.d/55atlas https://raw.githubusercontent.com/dkmur/aconf/develop/55atlas || { echo "`date +%Y-%m-%d_%T` Download 55atlas failed, exit script" >> $logfile ; exit 1; } ;do
        sleep 2
      done
      chmod +x /system/etc/init.d/55atlas
    else
      until /system/bin/curl -s -k -L --fail --show-error -o /system/etc/init.d/55atlas https://raw.githubusercontent.com/dkmur/aconf/master/55atlas || { echo "`date +%Y-%m-%d_%T` Download 55atlas failed, exit script" >> $logfile ; exit 1; } ;do
        sleep 2
      done
      chmod +x /system/etc/init.d/55atlas
    fi
    mount -o remount,ro /system
    new55=$(head -2 /system/etc/init.d/55atlas | grep '# version' | awk '{ print $NF }')
    echo "`date +%Y-%m-%d_%T` 55atlas $old55=>$new55" >> $logfile
  fi
fi

#update atlas monitor if needed
if [[ $(basename $0) = "atlas_new.sh" ]] ;then
  [ -f /system/bin/atlas_monitor.sh ] && oldMonitor=$(head -2 /system/bin/atlas_monitor.sh | grep '# version' | awk '{ print $NF }') || oldMonitor="0"
  if [ $VerMonitor != $oldMonitor ] ;then
    mount -o remount,rw /system
    if [ -f /sdcard/useAconfDevelop ] ;then
      until /system/bin/curl -s -k -L --fail --show-error -o /system/bin/atlas_monitor.sh https://raw.githubusercontent.com/dkmur/aconf/develop/atlas_monitor.sh || { echo "`date +%Y-%m-%d_%T` Download atlas_monitor failed, exit script" >> $logfile ; exit 1; } ;do
        sleep 2
      done
      chmod +x /system/bin/atlas_monitor.sh
    else
      until /system/bin/curl -s -k -L --fail --show-error -o /system/bin/atlas_monitor.sh https://raw.githubusercontent.com/dkmur/aconf/master/atlas_monitor.sh || { echo "`date +%Y-%m-%d_%T` Download atlas_monitor failed, exit script" >> $logfile ; exit 1; } ;do
        sleep 2
      done
      chmod +x /system/bin/atlas_monitor.sh
    fi
    mount -o remount,ro /system
    newMonitor=$(head -2 /system/bin/atlas_monitor.sh | grep '# version' | awk '{ print $NF }')
    echo "`date +%Y-%m-%d_%T` Atlas monitor $oldMonitor => $newMonitor" >> $logfile

    # restart atlas monitor
    if [[ $(grep useMonitor $aconf_versions | awk -F "=" '{ print $NF }') == "true" ]] && [ -f /system/bin/atlas_monitor.sh ] ;then
      checkMonitor=$(pgrep -f /system/bin/atlas_monitor.sh)
      if [ ! -z $checkMonitor ] ;then
        kill -9 $checkMonitor
        sleep 2
        /system/bin/atlas_monitor.sh >/dev/null 2>&1 &
        echo "`date +%Y-%m-%d_%T` Atlas monitor restarted" >> $logfile
      fi
    fi
  fi
fi


#update atvdetails sender if needed
if [[ $(basename $0) = "atlas_new.sh" ]] ;then
  [ -f /system/bin/ATVdetailsSender.sh ] && oldSender=$(head -2 /system/bin/ATVdetailsSender.sh | grep '# version' | awk '{ print $NF }') || oldSender="0"
  if [ $VerATVsender != $oldSender ] ;then
    mount -o remount,rw /system
    if [ -f /sdcard/useAconfDevelop ] ;then
      until /system/bin/curl -s -k -L --fail --show-error -o /system/bin/ATVdetailsSender.sh https://raw.githubusercontent.com/dkmur/aconf/develop/ATVdetailsSender.sh || { echo "`date +%Y-%m-%d_%T` Download ATVdetailsSender failed, exit script" >> $logfile ; exit 1; } ;do
        sleep 2
      done
      chmod +x /system/bin/ATVdetailsSender.sh
      echo "`date +%Y-%m-%d_%T` ATVdetails sender installed, from develop" >> $logfile
    else
      until /system/bin/curl -s -k -L --fail --show-error -o /system/bin/ATVdetailsSender.sh https://raw.githubusercontent.com/dkmur/aconf/master/ATVdetailsSender.sh || { echo "`date +%Y-%m-%d_%T` Download ATVdetailsSender failed, exit script" >> $logfile ; exit 1; } ;do
        sleep 2
      done
      chmod +x /system/bin/ATVdetailsSender.sh
      echo "`date +%Y-%m-%d_%T` ATVdetails sender installed, from master" >> $logfile
    fi
    mount -o remount,ro /system
    newSender=$(head -2 /system/bin/ATVdetailsSender.sh | grep '# version' | awk '{ print $NF }')
    echo "`date +%Y-%m-%d_%T` ATVdetails sender $oldSender => $newSender" >> $logfile

    # restart ATVdetails sender
    if [[ $(grep useSender $aconf_versions | awk -F "=" '{ print $NF }') == "true" ]] && [ -f /system/bin/ATVdetailsSender.sh ] ;then
      checkSender=$(pgrep -f /system/bin/ATVdetailsSender.sh)
      if [ ! -z $checkSender ] ;then
        kill -9 $checkSender
        sleep 2
      fi
      /system/bin/ATVdetailsSender.sh >/dev/null 2>&1 &
      echo "`date +%Y-%m-%d_%T` ATVdetails sender (re)started" >> $logfile
    fi
  fi
fi


# prevent aconf causing reboot loop. Add bypass ??
if [ $(cat /sdcard/aconf.log | grep `date +%Y-%m-%d` | grep rebooted | wc -l) -gt 20 ] ;then
  echo "`date +%Y-%m-%d_%T` Device rebooted over 20 times today, atlas.sh signing out, see you tomorrow"  >> $logfile
  exit 1
fi

# set hostname = origin, wait till next reboot for it to take effect
if [[ $origin != "" ]] ;then
  if [ $(cat /system/build.prop | grep net.hostname | wc -l) = 0 ]; then
    mount -o remount,rw /system
    echo "`date +%Y-%m-%d_%T` No hostname set, setting it to $origin" >> $logfile
    echo "net.hostname=$origin" >> /system/build.prop
    mount -o remount,ro /system
  else
    hostname=$(grep net.hostname /system/build.prop | awk 'BEGIN { FS = "=" } ; { print $2 }')
    if [[ $hostname != $origin ]] ;then
      mount -o remount,rw /system
      echo "`date +%Y-%m-%d_%T` Changing hostname, from $hostname to $origin" >> $logfile
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
if [[ $(grep useMonitor $aconf_versions | awk -F "=" '{ print $NF }') == "true" ]] && [ -f /system/bin/atlas_monitor.sh ] ;then
  checkMonitor=$(pgrep -f /system/bin/atlas_monitor.sh)
  if [ -z $checkMonitor ] ;then
    /system/bin/atlas_monitor.sh >/dev/null 2>&1 &
    echo "`date +%Y-%m-%d_%T` Atlas monitor enabled" >> $logfile
  fi
fi

# enable atvdetails sender
if [[ $(grep useSender $aconf_versions | awk -F "=" '{ print $NF }') == "true" ]] && [ -f /system/bin/ATVdetailsSender.sh ] ;then
  checkSender=$(pgrep -f /system/bin/ATVdetailsSender.sh)
  if [ -z $checkSender ] ;then
    /system/bin/ATVdetailsSender.sh >/dev/null 2>&1 &
    echo "`date +%Y-%m-%d_%T` ATVdetails sender started" >> $logfile
  fi
fi

for i in "$@" ;do
 case "$i" in
 -ia) install_atlas ;;
 -ic) install_config ;;
 -ua) update_all ;;
 -dp) downgrade_pogo;;
 -cr) check_rgc;;
 -sl) send_logs;;
# consider adding: downgrade atlas, update atlas config file, update donwload link
 esac
done


(( $reboot )) && reboot_device
exit
