#!/system/bin/sh
# version 0.16

#Version checks
Ver55atlas="0.3"
### add webhook sender?

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
[[ -f /data/local/tmp/aconf_download ]] && aconf_download=$(cat /data/local/tmp/aconf_download | head -n1 ) && echo "`date +%Y-%m-%d_%T` download folder set to $aconf_download" >> $logfile

# stderr to logfile
exec 2>> $logfile

# add atlas.sh command to log
echo "" >> $logfile
echo "`date +%Y-%m-%d_%T` ## Executing $(basename $0) $@" >> $logfile


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

[[ -f /data/local/tmp/aconf_download ]] && aconf_download=$(cat /data/local/tmp/aconf_download | head -n1 ) && echo "`date +%Y-%m-%d_%T` download folder set to $aconf_download" >> $logfile

# install 55atlas
mount -o remount,rw /system
until /system/bin/curl -s -k -L --fail --show-error -o /system/etc/init.d/55atlas https://raw.githubusercontent.com/dkmur/aconf/master/55atlas || { echo "`date +%Y-%m-%d_%T` Download 55atlas failed, exit script" >> $logfile ; exit 1; } ;do
  sleep 2
done
chmod +x /system/etc/init.d/55atlas
mount -o remount,ro /system
echo "`date +%Y-%m-%d_%T` 55atlas installed" >> $logfile

# get version
aversion=$(head -2 /data/local/tmp/aconf_versions | grep 'atlas' | awk -F "=" '{ print $NF }')

# download atlas
/system/bin/rm -f /sdcard/Download/atlas.apk
until /system/bin/curl -k -s -L --fail --show-error -o /sdcard/Download/atlas.apk $aconf_download/PokemodAtlas-Public-$aversion.apk || { echo "`date +%Y-%m-%d_%T` Download atlas failed, exit script" >> $logfile ; exit 1; } ;do
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

# let us kill pogo as well and clear data
pm clear com.nianticlabs.pokemongo
am force-stop com.nianticlabs.pokemongo

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
until /system/bin/curl -s -k -L --fail --show-error -o /data/local/tmp/atlas_config.json $aconf_download/atlas_config.json || { echo "`date +%Y-%m-%d_%T` Download atlas config file failed, exit script" >> $logfile ; exit 1; } ;do
  sleep 2
done
rgc_origin=$(grep -w 'websocket_origin' $rgcconf | sed -e 's/    <string name="websocket_origin">\(.*\)<\/string>/\1/')
sed -i 's,dummy,'$rgc_origin',g' /data/local/tmp/atlas_config.json

# check pogo version else remove+install
downgrade_pogo

# check if rgc is to be enabled or disabled
check_rgc

# start atlas
am startservice com.pokemod.atlas/com.pokemod.atlas.services.MappingService
sleep 5

# Set for reboot device
reboot=1
}

update_all(){
pinstalled=$(dumpsys package com.nianticlabs.pokemongo | grep versionName | head -n1 | sed 's/ *versionName=//')
pversions=$(head -2 /data/local/tmp/aconf_versions | grep 'pogo' | awk -F "=" '{ print $NF }')
ainstalled=$(dumpsys package com.pokemod.atlas | grep versionName | head -n1 | sed 's/ *versionName=//')
aversions=$(head -2 /data/local/tmp/aconf_versions | grep 'atlas' | awk -F "=" '{ print $NF }' | awk '{print substr($1,2); }')

if [ $pinstalled != $pversions ] ;then
  echo "`date +%Y-%m-%d_%T` New pogo version detected, $pinstalled=>$pversions" >> $logfile
  /system/bin/rm -f /sdcard/Download/pogo.apk
  until /system/bin/curl -s -k -L --fail --show-error -o /sdcard/Download/pogo.apk $aconf_download/pokemongo_$arch\_$pversions.apk || { echo "`date +%Y-%m-%d_%T` Download pogo failed, exit script" >> $logfile ; exit 1; } ;do
    sleep 2
  done
  # set pogo to be installed
  pogo_install="install"
else
 pogo_install="skip"
 echo "`date +%Y-%m-%d_%T` PoGo already on correct version" >> $logfile
fi

if [ $ainstalled != $aversions ] ;then
  echo "`date +%Y-%m-%d_%T` New atlas version detected, $ainstalled=>$aversions" >> $logfile
  /system/bin/rm -f /sdcard/Download/atlas.apk
  until /system/bin/curl -k -s -L --fail --show-error -o /sdcard/Download/atlas.apk $aconf_download/PokemodAtlas-Public-$aversion.apk || { echo "`date +%Y-%m-%d_%T` Download atlas failed, exit script" >> $logfile ; exit 1; } ;do
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
    /system/bin/pm install -r /sdcard/Download/atlas.apk || { echo "`date +%Y-%m-%d_%T` Install  atlas failed, downgrade perhaps? Exit script" >> $logfile ; exit 1; }
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
  rgccheck=$(head -2 /data/local/tmp/aconf_versions | grep 'rgc' | awk -F "=" '{ print $NF }')
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
pversions=$(head -2 /data/local/tmp/aconf_versions | grep 'pogo' | awk -F "=" '{ print $NF }')
if [ $pinstalled != $pversions ] ;then
  until /system/bin/curl -s -k -L --fail --show-error -o /sdcard/Download/pogo.apk $aconf_download/pokemongo_$arch\_$pversions.apk || { echo "`date +%Y-%m-%d_%T` Download pogo failed, exit script" >> $logfile ; exit 1; } ;do
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

  until /system/bin/curl -s -k -L --fail --show-error -o /system/bin/atlas_new.sh https://raw.githubusercontent.com/dkmur/aconf/master/atlas.sh || { echo "`date +%Y-%m-%d_%T` Download atlas.sh failed, exit script" >> $logfile ; exit 1; } ;do
    sleep 2
  done
  chmod +x /system/bin/atlas_new.sh

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

#update 55atlas if needed
if [[ $(basename $0) = "atlas_new.sh" ]] ;then
  old55=$(head -2 /system/etc/init.d/55atlas | grep '# version' | awk '{ print $NF }')
  if [ $Ver55atlas != $old55 ] ;then
    mount -o remount,rw /system
    until /system/bin/curl -s -k -L --fail --show-error -o /system/etc/init.d/55atlas https://raw.githubusercontent.com/dkmur/aconf/master/55atlas || { echo "`date +%Y-%m-%d_%T` Download 55atlas failed, exit script" >> $logfile ; exit 1; } ;do
      sleep 2
    done
    chmod +x /system/etc/init.d/55atlas
    mount -o remount,ro /system
    new55=$(head -2 /system/etc/init.d/55atlas | grep '# version' | awk '{ print $NF }')
    echo "`date +%Y-%m-%d_%T` 55atlas $old55=>$new55" >> $logfile
  fi
fi

### verify dowload folder ??

# prevent amconf causing reboot loop. Add bypass ??
if [ $(cat /sdcard/aconf.log | grep `date +%Y-%m-%d` | grep rebooted | wc -l) -gt 20 ] ;then
  echo "`date +%Y-%m-%d_%T` Device rebooted over 20 times today, atlas.sh signing out, see you tomorrow"  >> $logfile
  exit 1
fi

# download latest version file
until /system/bin/curl -s -k -L --fail --show-error -o /data/local/tmp/aconf_versions $aconf_download/versions || { echo "`date +%Y-%m-%d_%T` Download atlas version file failed, exit script" >> $logfile ; exit 1; } ;do
  sleep 2
done

# check rgc enable/disable
check_rgc

for i in "$@" ;do
 case "$i" in
 -ia) install_atlas ;;
 -ua) update_all ;;
 -dp) downgrade_pogo;;
# consider adding: downgrade pogo, downgrade atlas, update atlas config file, update donwload link
 esac
done


(( $reboot )) && reboot_device
exit
