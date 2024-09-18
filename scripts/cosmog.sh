#!/system/bin/sh
# version 2.3.7

#Version checks
Ver42cosmog="1.6"
Ver55cosmog="1.1"
VerMonitor="3.4.2"
VerATVsender="1.9.3"

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
aconf="/data/local/tmp/cosmog.json"
aconf_versions="/data/local/aconf_versions"
aconf_mac2name="/data/local/aconf_mac2name"
[[ -f /data/local/aconf_download ]] && url=$(grep url /data/local/aconf_download | awk -F "=" '{ print $NF }')
[[ -f /data/local/aconf_download ]] && aconf_user=$(grep authUser /data/local/aconf_download | awk -F "=" '{ print $NF }')
[[ -f /data/local/aconf_download ]] && aconf_pass=$(grep authPass /data/local/aconf_download | awk -F "=" '{ print $NF }')
discord_webhook=$(grep 'discord_webhook' $aconf_versions | awk -F "=" '{ print $NF }' | sed -e 's/^"//' -e 's/"$//')
if [[ -z $discord_webhook ]] ;then
  discord_webhook=$(grep discord_webhook /data/local/aconf_download | awk -F "=" '{ print $NF }' | sed -e 's/^"//' -e 's/"$//')
fi

if [[ -f /data/local/tmp/cosmog.json ]] ;then
# origin=$(grep -w 'deviceName' $aconf | awk -F "\"" '{ print $4 }')
  origin=$(cat $aconf | tr , '\n' | grep -w 'device_id' | awk -F "\"" '{ print $4 }')
else
  if [[ -f /data/data/de.grennith.rgc.remotegpscontroller/shared_prefs/de.grennith.rgc.remotegpscontroller_preferences.xml ]] ;then
    origin=$(grep -w 'websocket_origin' $rgcconf | sed -e 's/    <string name="websocket_origin">\(.*\)<\/string>/\1/')
  else
    echo "`date +%Y-%m-%d_%T` cosmog.sh: cannot find origin, that can't be right" >> $logfile
  fi
fi

# stderr to logfile
exec 2>> $logfile

# add cosmog.sh command to log
echo "" >> $logfile
echo "`date +%Y-%m-%d_%T` cosmog.sh: executing $(basename $0) $@" >> $logfile
# echo "`date +%Y-%m-%d_%T` download folder set to $url, user is $aconf_user with pass $aconf_pass" >> $logfile


########## Functions

# logger
logger() {
if [[ ! -z $discord_webhook ]] ;then
  echo "`date +%Y-%m-%d_%T` cosmog.sh: $1" >> $logfile
  if [[ -z $origin ]] ;then
    curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"cosmog.sh\", \"content\": \" $1 \"}"  $discord_webhook &>/dev/null
  else
    curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"cosmog.sh\", \"content\": \" $origin: $1 \"}"  $discord_webhook &>/dev/null
  fi
else
  echo "`date +%Y-%m-%d_%T` cosmog.sh: $1" >> $logfile
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

install_cosmog(){
  mount_system_rw
  setup_initd_dir
  if [ ! -f /system/etc/init.d/42cosmog ] ;then
    until $download /system/etc/init.d/55cosmog $url/scripts/55cosmog || { logger "download 55cosmog failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    chmod +x /system/etc/init.d/55cosmog
    logger "55cosmog installed"
  fi

if [ $android_version -ge 9 ]; then
    cat <<EOF > /system/etc/init/55cosmog.rc
on property:sys.boot_completed=1
    exec_background u:r:init:s0 root root -- /system/etc/init.d/55cosmog
EOF
    chown root:root /system/etc/init/55cosmog.rc
    chmod 644 /system/etc/init/55cosmog.rc
    logger "55cosmog.rc installed"
fi

# install cosmog monitor
  until $download /system/bin/cosmog_monitor.sh $url/scripts/cosmog_monitor.sh || { logger "download cosmog_monitor.sh failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/bin/cosmog_monitor.sh
  logger "cosmog monitor installed"


if [ $android_version -ge 9 ]; then
                cat <<EOF > /system/etc/init/cosmog_monitor.rc
on property:sys.boot_completed=1
                exec_background u:r:init:s0 root root -- /system/bin/cosmog_monitor.sh
EOF
                chown root:root /system/etc/init/cosmog_monitor.rc
                chmod 644 /system/etc/init/cosmog_monitor.rc
                logger "cosmog_monitor.rc installed"

fi

  # install cosmogDetails sender
    until $download /system/bin/CosmogDetailsSender.sh $url/scripts/CosmogDetailsSender.sh || { logger "download CosmogDetailsSender.sh failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    chmod +x /system/bin/CosmogDetailsSender.sh
    logger "cosmogDetails sender installed"
    mount_system_ro

  # get version
  aversions=$(grep 'cosmog' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')

  # download cosmog
  /system/bin/rm -f /sdcard/Download/cosmog.apk
  until $download /sdcard/Download/cosmog.apk $url/apk/cosmog-$aversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/cosmog.apk $url/apk/cosmog-$aversions.apk" >> $logfile ; logger "download cosmog failed, exit script" ; exit 1; } ;do
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

  # Install cosmog
  /system/bin/pm install -r /sdcard/Download/cosmog.apk
  /system/bin/rm -f /sdcard/Download/cosmog.apk
  logger "cosmog installed"

  # Grant su access + settings
  auid="$(dumpsys package com.sy1vi3.cosmog | grep userId | awk -F'=' '{print $2}')"
  magisk --sqlite "REPLACE INTO policies (uid,policy,until,logging,notification) VALUES($auid,2,0,1,0)"
  #pm grant com.sy1vi3.cosmog android.permission.READ_EXTERNAL_STORAGE
  #pm grant com.sy1vi3.cosmog android.permission.WRITE_EXTERNAL_STORAGE
  logger "cosmog granted su and settings set"

  # add common packages to denylist
  magisk --sqlite "REPLACE INTO denylist (package_name,process) VALUES('com.android.vending','com.android.vending');"
  magisk --sqlite "REPLACE INTO denylist (package_name,process) VALUES('com.google.android.gms','com.google.android.gms');"
  magisk --sqlite "REPLACE INTO denylist (package_name,process) VALUES('com.google.android.gms.setup','com.google.android.gms.setup');"
  magisk --sqlite "REPLACE INTO denylist (package_name,process) VALUES('com.google.android.gsf','com.google.android.gsf');"
  magisk --sqlite "REPLACE INTO denylist (package_name,process) VALUES('com.nianticlabs.pokemongo','com.nianticlabs.pokemongo');"

  # add cosmog workers to denylist
  i=1
  while [ $i -le 100 ]; do
    magisk --sqlite "REPLACE INTO denylist (package_name,process) VALUES('com.sy1vi3.cosmog','com.sy1vi3.cosmog:worker$i.com.nianticlabs.pokemongo');"
    i=$((i + 1))
  done

  # enable zygisk
  magisk --sqlite "REPLACE INTO settings (key,value) VALUES('zygisk',1);"

  # enable denylist
  magisk --sqlite "REPLACE INTO settings (key,value) VALUES('denylist',1);"
  magisk --denylist enable

  #download newest cosmog lib file
  cosmog_lib

  # Replace these paths with your actual source and target paths
  cosmog_dir="/data/data/com.sy1vi3.cosmog"
  files_dir="$cosmog_dir/files"

  # Extract owner, group, and permissions
  owner=$(stat -c "%U" "$cosmog_dir")
  group=$(stat -c "%G" "$cosmog_dir")
  perms=$(stat -c "%a" "$cosmog_dir")
  # Apply the owner and group to the target
  chown -R "$owner":"$group" "$files_dir"
  # Apply the permissions to the target
  chmod -R "$perms" "$files_dir"

  # download cosmog config file and adjust orgin to rgc setting
  install_config

  # check pogo version else remove+install
  downgrade_pogo

  # supress 'pink screen'
  opengl_warning

  # check if rgc is to be enabled or disabled
  check_rgc

  # start cosmog
  am start -n com.sy1vi3.cosmog/com.sy1vi3.cosmog.MainActivity
  sleep 10

  # Set for reboot device
  reboot=1

  ## Send final webhook
  # discord_config_wh=$(grep 'discord_webhook' $aconf_versions | awk -F "=" '{ print $NF }')
  ip=$(ifconfig eth0 |grep 'inet addr' |cut -d ':' -f2 |cut -d ' ' -f1)
  logger "new cosmog device configured. IP: $ip"
}

install_config(){
  until $download /data/local/tmp/cosmog.json $url/cosmog_config.json || { echo "`date +%Y-%m-%d_%T` $download /data/local/tmp/cosmog.json $url/cosmog_config.json" >> $logfile ; logger "download cosmog config file failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  if [[ ! -z $origin ]] ;then
    sed -i 's,dummy,'$origin',g' $aconf
    logger "cosmog config installed, set devicename to $origin"
  else
    temporigin="TEMP-$(date +'%H_%M_%S')"
    sed -i 's,dummy,'$temporigin',g' $aconf
    logger "cosmog config installed, set devicename to $temporigin"
  fi
}

update_cosmog_config(){
  if [[ -z $origin ]] ;then
    logger "will not replace cosmog config file without deviceName being set"
  else
    until $download /data/local/tmp/cosmog.json $url/cosmog_config.json || { echo "`date +%Y-%m-%d_%T` $download /data/local/tmp/cosmog.json $url/cosmog_config.json" >> $logfile ; logger "download cosmog config file failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    sed -i 's,dummy,'$origin',g' $aconf

    am force-stop com.sy1vi3.cosmog && am start -n com.sy1vi3.cosmog/com.sy1vi3.cosmog.MainActivity

    logger "cosmog config updated and cosmog restarted"
  fi
}

cosmog_lib(){
  vLibVer=$(grep 'cosmog_libVerion' $aconf_versions | awk -F "=" '{ print $NF }' | sed 's/\"//g')
  if [[ ! -d /data/data/com.sy1vi3.cosmog/files ]] ;then
    mkdir -p /data/data/com.sy1vi3.cosmog/files/
  fi
  if [[ ! -f /data/data/com.sy1vi3.cosmog/files/libNianticLabsPlugin.so ]] ;then
    logger "Cosmog Lib not found, downloading it"
    rm -f /data/local/tmp/libNianticLabsPlugin.so_*
    until $download /data/local/tmp/libNianticLabsPlugin.so_$vLibVer $url/modules/libNianticLabsPlugin.so_$vLibVer || { echo "`date +%Y-%m-%d_%T` $download /data/local/tmp/libNianticLabsPlugin.so_$vLibVer $url/modules/libNianticLabsPlugin.so_$vLibVer" >> $logfile ; logger "download cosmog lib file failed, exit script" ; exit 1; } ;do
      sleep 2
    done
  else
    iLibVer=$(find /data/local/tmp/ -type f -name "libNianticLabsPlugin.so_*" | cut -d '_' -f 2)
    if [[ $vLibVer != $iLibVer ]] ;then
      logger "Cosmog Lib too old, downloading new version"
      rm -f /data/local/tmp/libNianticLabsPlugin.so_*
      until $download /data/local/tmp/libNianticLabsPlugin.so_$vLibVer $url/modules/libNianticLabsPlugin.so_$vLibVer || { echo "`date +%Y-%m-%d_%T` $download /data/local/tmp/libNianticLabsPlugin.so_$vLibVer $url/modules/libNianticLabsPlugin.so_$vLibVer" >> $logfile ; logger "download cosmog lib file failed, exit script" ; exit 1; } ;do
        sleep 2
      done
    else
      echo "`date +%Y-%m-%d_%T` cosmog.sh: cosmog lib already on correct version" >> $logfile
    fi
  fi

  #Move lib and set perms
  cp /data/local/tmp/libNianticLabsPlugin.so_$vLibVer /data/data/com.sy1vi3.cosmog/files/libNianticLabsPlugin.so
  chown root:root /data/data/com.sy1vi3.cosmog/files/libNianticLabsPlugin.so
  chmod 444 /data/data/com.sy1vi3.cosmog/files/libNianticLabsPlugin.so
}

update_all(){
  pinstalled=$(dumpsys package com.nianticlabs.pokemongo | grep versionName | head -n1 | sed 's/ *versionName=//')
  pversions=$(grep 'pogo' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')
  ainstalled=$(dumpsys package com.sy1vi3.cosmog | grep versionName | head -n1 | sed 's/ *versionName=//' | sed 's/-fix//' )
  aversions=$(grep 'cosmog' $aconf_versions | grep -v '_' | awk -F "=" '{ print $NF }')

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
      until $download /sdcard/Download/pogo_split.apk $url/apk/pokemongo_$arch\_$pversions\_split.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/pogo_split.apk $url/apk/pokemongo_$arch\_$pversions\_base.apk" >> $logfile ; logger "download pogo split failed, exit script" ; exit 1; } ;do
        sleep 2
      done
      # set pogo to be installed
      pogo_install="install"
    fi
  else
  pogo_install="skip"
  echo "`date +%Y-%m-%d_%T` cosmog.sh: pogo already on correct version" >> $logfile
  fi

  if [ $ainstalled != $aversions ] ;then
    logger "new cosmog version detected, $ainstalled=>$aversions"
    ver_cosmog_md5=$(grep 'cosmog_md5' $aconf_versions | awk -F "=" '{ print $NF }')
    if [[ ! -z $ver_cosmog_md5 ]] ;then
      inst_cosmog_md5=$(md5sum /data/app/com.sy1vi3.cosmog-*/base.apk | awk '{print $1}')
      if [[ $ver_cosmog_md5 == $inst_cosmog_md5 ]] ;then
        logger "New version but same md5 - skip install"
        cosmog_install="skip"
      else
        logger "New version, new md5 - start install"
        /system/bin/rm -f /sdcard/Download/cosmog.apk
        until $download /sdcard/Download/cosmog.apk $url/apk/cosmog-$aversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/cosmog.apk $url/apk/cosmog-$aversions.apk" >> $logfile ; logger "download cosmog failed, exit script" ; exit 1; } ;do
          sleep 2
        done
        # set cosmog to be installed
        cosmog_install="install"
      fi
    else
      logger "No md5 found, install new version regardless"
      /system/bin/rm -f /sdcard/Download/cosmog.apk
      until $download /sdcard/Download/cosmog.apk $url/apk/cosmog-$aversions.apk || { echo "`date +%Y-%m-%d_%T` $download /sdcard/Download/cosmog.apk $url/apk/cosmog-$aversions.apk" >> $logfile ; logger "download cosmog failed, exit script" ; exit 1; } ;do
        sleep 2
      done
      # set cosmog to be installed
      cosmog_install="install"
    fi
  else
  cosmog_install="skip"
  echo "`date +%Y-%m-%d_%T` cosmog.sh: cosmog already on correct version" >> $logfile
  fi

  if [ ! -z "$cosmog_install" ] && [ ! -z "$pogo_install" ] ;then
    echo "`date +%Y-%m-%d_%T` cosmog.sh: all updates checked and downloaded if needed" >> $logfile
    if [ "$cosmog_install" = "install" ] ;then
      Logger "Updating cosmog"
      # install cosmog
      /system/bin/pm install -r /sdcard/Download/cosmog.apk || { logger "install cosmog failed, downgrade perhaps? Exit script" ; exit 1; }
      /system/bin/rm -f /sdcard/Download/cosmog.apk
      reboot=1
    fi
    if [ "$pogo_install" = "install" ] ;then
      logger "updating pogo"
      # install pogo
      /system/bin/pm install -r /sdcard/Download/pogo_base.apk && /system/bin/pm install -p com.nianticlabs.pokemongo -r /sdcard/Download/pogo_split.apk || { logger "install pogo failed, downgrade perhaps? Exit script" ; exit 1; }
      /system/bin/rm -f /sdcard/Download/pogo_*.apk
      reboot=1
    fi
    if [ "$cosmog_install" != "install" ] && [ "$pogo_install" != "install" ] ; then
      echo "`date +%Y-%m-%d_%T` cosmog.sh: updates checked, nothing to install" >> $logfile
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
    echo "`date +%Y-%m-%d_%T` cosmog.sh: pogo version correct, proceed" >> $logfile
  fi
}

send_logs(){
  if [[ -z $webhook ]] ;then
    echo "`date +%Y-%m-%d_%T` cosmog.sh: no webhook set in job" >> $logfile
  else
    # aconf log
    curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aconf log sender\", \"content\": \"aconf.log for $origin\"}" -F "file1=@$logfile" $webhook &>/dev/null
    # monitor log
    [[ -f /sdcard/cosmog_monitor.log ]] && curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aconf log sender\", \"content\": \"cosmog_monitor.log for $origin\"}" -F "file1=@/sdcard/cosmog_monitor.log" $webhook &>/dev/null
    # cosmog log
    cp /data/local/tmp/cosmog.log /sdcard/cosmog.log
    curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aconf log sender\", \"content\": \"cosmog.log for $origin\"}" -F "file1=@/sdcard/cosmog.log" $webhook &>/dev/null
    rm /sdcard/cosmog.log
    #logcat
    logcat -d > /sdcard/logcat.txt
    curl -S -k -L --fail --show-error -F "payload_json={\"username\": \"aconf log sender\", \"content\": \"logcat.txt for $origin\"}" -F "file1=@/sdcard/logcat.txt" $webhook &>/dev/null
    rm -f /sdcard/logcat.txt
    echo "`date +%Y-%m-%d_%T` cosmog.sh: sending logs to discord" >> $logfile
  fi
}

opengl_warning() {
  # Fetch OpenGL version and extract major version directly
  opengl_version=$(dumpsys SurfaceFlinger | grep -o "OpenGL ES [0-9]*\.[0-9]*" | sed -n 's/OpenGL ES \([0-9]*\)\..*/\1/p')

  # Check if major_version was successfully extracted
  if [[ -z "$opengl_version" ]]; then
      echo "`date +%Y-%m-%d_%T` cosmog.sh: [xml] failed to extract the OpenGL version."  >> $logfile
      return 1
  fi

  # Compare the major version number
  if [[ $opengl_version -ge 3 ]]; then
      echo "`date +%Y-%m-%d_%T` cosmog.sh: [xml] opengl is 3+, skipping" >> $logfile
  else
      echo "`date +%Y-%m-%d_%T` cosmog.sh: [xml] OpenGL version is less than 3. Downloading XML file." >> $logfile

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
echo "`date +%Y-%m-%d_%T` cosmog.sh: internet connection available" >> $logfile

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

#download latest cosmog.sh
if [[ $(basename $0) != "cosmog_new.sh" ]] ;then
  mount_system_rw
  oldsh=$(head -2 /system/bin/cosmog.sh | grep '# version' | awk '{ print $NF }')
  until $download /system/bin/cosmog_new.sh $url/scripts/cosmog.sh || { logger "download cosmog.sh failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/bin/cosmog_new.sh
  newsh=$(head -2 /system/bin/cosmog_new.sh | grep '# version' | awk '{ print $NF }')
  if [[ $oldsh != $newsh ]] ;then
    logger "cosmog.sh updated $oldsh=>$newsh, restarting script"
#   folder=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    cp /system/bin/cosmog_new.sh /system/bin/cosmog.sh
    mount_system_ro
    /system/bin/cosmog_new.sh $@
    exit 1
  fi
fi

# download latest version file
until $download $aconf_versions $url/versions || { echo "`date +%Y-%m-%d_%T` $download $aconf_versions $url/versions" >> $logfile ; logger "download cosmog versions file failed, exit script" ; exit 1; } ;do
  sleep 2
done
dos2unix $aconf_versions
echo "`date +%Y-%m-%d_%T` cosmog.sh: downloaded latest versions file"  >> $logfile

# download latest mac2name file
until $download $aconf_mac2name $url/mac2name || { echo "`date +%Y-%m-%d_%T` $download $aconf_mac2name $url/mac2name" >> $logfile ; logger "download cosmog mac2name file failed, skip naming" ; } ;do
  sleep 2
done
dos2unix $aconf_mac2name
echo "`date +%Y-%m-%d_%T` cosmog.sh: downloaded latest mac2name file"  >> $logfile
if [[ $origin = "" ]] ;then
  mac=$(ifconfig wlan0 2>/dev/null | grep 'HWaddr' | awk '{print $5}' | cut -d ' ' -f1 && ifconfig eth0 2>/dev/null | grep 'HWaddr' | awk '{print $5}')
  origin=$(grep -m 1 -i $mac $aconf_mac2name | cut -d ';' -f2)
  hostname=$origin
  if [[ $origin != "" ]] ;then
    echo "`date +%Y-%m-%d_%T` cosmog.sh: got origin name $origin from mac2name file"  >> $logfile
  else
    mac=$(ifconfig wlan0 2>/dev/null | grep 'HWaddr' | awk '{print $5}' | cut -d ' ' -f1 && ifconfig eth0 2>/dev/null | grep 'HWaddr' | awk '{print $5}')
    logger "no origin name found in mac2name file, add it with mac $mac"
  fi
fi


#update 42cosmog if needed
if [[ $(basename $0) = "cosmog_new.sh" ]] ;then
  if [[ -f /system/etc/init.d/42cosmog ]] ;then
    old42=$(head -2 /system/etc/init.d/42cosmog | grep '# version' | awk '{ print $NF }')
    if [ $Ver42cosmog != $old42 ] ;then
      mount_system_rw
      setup_initd_dir
      until $download /system/etc/init.d/42cosmog $url/scripts/42cosmog || { logger "download 42cosmog failed, exit script" ; exit 1; } ;do
        sleep 2
      done
      chmod +x /system/etc/init.d/42cosmog
      mount_system_ro
      new42=$(head -2 /system/etc/init.d/42cosmog | grep '# version' | awk '{ print $NF }')
      logger "42cosmog updated $old42=>$new42"
    fi
  fi
fi

#update 55cosmog if needed
if [[ $(basename $0) = "cosmog_new.sh" ]] ;then
  if [[ -f /system/etc/init.d/55cosmog ]] ;then
    old55=$(head -2 /system/etc/init.d/55cosmog | grep '# version' | awk '{ print $NF }')
    if [ $Ver55cosmog != $old55 ] ;then
      mount_system_rw
      setup_initd_dir
      until $download /system/etc/init.d/55cosmog $url/scripts/55cosmog || { logger "download 55cosmog failed, exit script" ; exit 1; } ;do
        sleep 2
      done
      chmod +x /system/etc/init.d/55cosmog
      mount_system_ro
      new55=$(head -2 /system/etc/init.d/55cosmog | grep '# version' | awk '{ print $NF }')
      logger "55cosmog updated $old55=>$new55"
    fi
  fi
fi

#update cosmog monitor if needed
if [[ $(basename $0) = "cosmog_new.sh" ]] ;then
  [ -f /system/bin/cosmog_monitor.sh ] && oldMonitor=$(head -2 /system/bin/cosmog_monitor.sh | grep '# version' | awk '{ print $NF }') || oldMonitor="0"
  if [ $VerMonitor != $oldMonitor ] ;then
    mount_system_rw
    until $download /system/bin/cosmog_monitor.sh $url/scripts/cosmog_monitor.sh || { logger "download cosmog_monitor.sh failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    chmod +x /system/bin/cosmog_monitor.sh
    mount_system_ro
    newMonitor=$(head -2 /system/bin/cosmog_monitor.sh | grep '# version' | awk '{ print $NF }')
    logger "cosmog monitor updated $oldMonitor => $newMonitor"

    # restart cosmog monitor
    if [[ $(grep useMonitor $aconf_versions | awk -F "=" '{ print $NF }') == "true" ]] && [ -f /system/bin/cosmog_monitor.sh ] ;then
      checkMonitor=$(pgrep -f /system/bin/cosmog_monitor.sh)
      if [ ! -z $checkMonitor ] ;then
        kill -9 $checkMonitor
        sleep 2
        /system/bin/cosmog_monitor.sh >/dev/null 2>&1 &
        logger "cosmog monitor restarted"
      fi
    fi
  fi
fi

#update cosmogDetails sender if needed
if [[ $(basename $0) = "cosmog_new.sh" ]] ;then
  [ -f /system/bin/CosmogDetailsSender.sh ] && oldSender=$(head -2 /system/bin/CosmogDetailsSender.sh | grep '# version' | awk '{ print $NF }') || oldSender="0"
  if [ $VerATVsender != $oldSender ] ;then
    mount_system_rw
    until $download /system/bin/CosmogDetailsSender.sh $url/scripts/CosmogDetailsSender.sh || { logger "download CosmogDetailsSender.sh failed, exit script" ; exit 1; } ;do
      sleep 2
    done
    chmod +x /system/bin/CosmogDetailsSender.sh
    mount_system_ro
    newSender=$(head -2 /system/bin/CosmogDetailsSender.sh | grep '# version' | awk '{ print $NF }')
    logger "cosmogDetails sender updated $oldSender => $newSender"

    # restart cosmogDetails sender
    if [[ $(grep useSender $aconf_versions | awk -F "=" '{ print $NF }') == "true" ]] && [ -f /system/bin/CosmogDetailsSender.sh ] ;then
      checkSender=$(pgrep -f /system/bin/CosmogDetailsSender.sh)
      if [ ! -z $checkSender ] ;then
        kill -9 $checkSender
        sleep 2
      fi
      /system/bin/CosmogDetailsSender.sh >/dev/null 2>&1 &
      logger "cosmogDetails sender (re)started"
    fi
  fi
fi


# prevent aconf causing reboot loop. Add bypass ?? <- done :)
loop_protect_enabled=$(grep 'loop_protect_enabled' $aconf_versions | awk -F "=" '{ print $NF }')
if [[ $(cat /sdcard/aconf.log | grep `date +%Y-%m-%d` | grep rebooted | grep -v "over 20 times" | wc -l) -gt 20 ]] ;then
  if [[ $loop_protect_enabled != "false" ]] ;then
    logger "device rebooted over 20 times today, cosmog.sh signing out, see you tomorrow"
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

# check cosmog config file exists
if [[ -d /data/data/com.sy1vi3.cosmog ]] && [[ ! -s $aconf ]] ;then
  install_config
  am force-stop com.sy1vi3.cosmog
  sleep 1
  am start -n com.sy1vi3.cosmog/com.sy1vi3.cosmog.MainActivity
fi

# check 16/42mad pogo autoupdate disabled
! [[ -f /sdcard/disableautopogoupdate ]] && touch /sdcard/disableautopogoupdate

# check for webhook
if [[ $2 == https://* ]] ;then
  webhook=$2
fi

# enable cosmog monitor
if [[ $(grep useMonitor $aconf_versions | awk -F "=" '{ print $NF }' | awk '{ gsub(/ /,""); print }') == "true" ]] && [ -f /system/bin/cosmog_monitor.sh ] ;then
  checkMonitor=$(pgrep -f /system/bin/cosmog_monitor.sh)
  if [ -z $checkMonitor ] ;then
    /system/bin/cosmog_monitor.sh >/dev/null 2>&1 &
    echo "`date +%Y-%m-%d_%T` cosmog.sh: cosmog monitor enabled" >> $logfile
  fi
fi

# enable cosmogDetails sender
if [[ $(grep useSender $aconf_versions | awk -F "=" '{ print $NF }' | awk '{ gsub(/ /,""); print }') == "true" ]] && [ -f /system/bin/CosmogDetailsSender.sh ] ;then
  checkSender=$(pgrep -f /system/bin/CosmogDetailsSender.sh)
  if [ -z $checkSender ] ;then
    /system/bin/CosmogDetailsSender.sh >/dev/null 2>&1 &
    echo "`date +%Y-%m-%d_%T` cosmog.sh: cosmogDetails sender started" >> $logfile
  fi
fi

# check cosmog running
cosmog_check=$(ps -e | grep com.sy1vi3.cosmog | awk '{print $9}')
if [[ -z $cosmog_check ]] && [[ -f /data/local/tmp/cosmog.json ]] ;then
  logger "cosmog not running at execution of cosmog.sh, starting it"
  am start -n com.sy1vi3.cosmog/com.sy1vi3.cosmog.MainActivity
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
    am force-stop com.sy1vi3.cosmog
    am force-stop com.nianticlabs.pokemongo
    /sbin/magisk --install-module /sdcard/Download/PIF_module.zip
    logger "Updated PIF module from $instPIFv to $versionsPIFv"
    reboot=1
  else
    echo "`date +%Y-%m-%d_%T` cosmog.sh: PIF module correct, proceed" >> $logfile
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
    echo "`date +%Y-%m-%d_%T` cosmog.sh: FingerPrint correct, proceed" >> $logfile
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
    echo "`date +%Y-%m-%d_%T` cosmog.sh: CustomJob Up2Date, proceed" >> $logfile
  fi
fi

# check cosmog lib ver
vLibVer=$(grep 'cosmog_libVerion' $aconf_versions | awk -F "=" '{ print $NF }' | sed 's/\"//g')
iLibVer=$(find /data/local/tmp/ -type f -name "libNianticLabsPlugin.so_*" | cut -d '_' -f 2)
if [[ $vLibVer != $iLibVer ]] ;then
  logger "Cosmog Lib not matched, downloading new version"
  rm -f /data/local/tmp/libNianticLabsPlugin.so_*
  until $download /data/local/tmp/libNianticLabsPlugin.so_$vLibVer $url/modules/libNianticLabsPlugin.so_$vLibVer || { echo "`date +%Y-%m-%d_%T` $download /data/local/tmp/libNianticLabsPlugin.so_$vLibVer $url/modules/libNianticLabsPlugin.so_$vLibVer" >> $logfile ; logger "download cosmog lib file failed, exit script" ; exit 1; } ;do
    sleep 2
  done
  #Move lib and set perms
  cp /data/local/tmp/libNianticLabsPlugin.so_$vLibVer /data/data/com.sy1vi3.cosmog/files/libNianticLabsPlugin.so
  chown root:root /data/data/com.sy1vi3.cosmog/files/libNianticLabsPlugin.so
  chmod 444 /data/data/com.sy1vi3.cosmog/files/libNianticLabsPlugin.so
else
  echo "`date +%Y-%m-%d_%T` cosmog.sh: cosmog lib already on correct version" >> $logfile
fi


for i in "$@" ;do
 case "$i" in
 -ia) install_cosmog ;;
 -ic) install_config ;;
 -ua) update_all ;;
 -uac) update_cosmog_config ;;
 -dp) downgrade_pogo;;
 -cr) check_rgc;;
 -sl) send_logs;;
# consider adding: downgrade cosmog, update donwload link
 esac
done


(( $reboot )) && reboot_device
exit