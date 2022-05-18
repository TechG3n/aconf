#!/system/bin/sh
# version 0.1

#Version checks
Ver55atlas="0.1"
### add webhook sender?

#Create logfile
if [ ! -e /sdcard/aconf.log ] ;then
    touch /sdcard/aconf.log
fi

logfile="/sdcard/aconf.log"
#[[ -d /data/data/com.mad.pogodroid ]] && puser=$(ls -la /data/data/com.mad.pogodroid/ | head -n2 | tail -n1 | awk '{print $3}')
#pdconf="/data/data/com.mad.pogodroid/shared_prefs/com.mad.pogodroid_preferences.xml"
#[[ -d /data/data/de.grennith.rgc.remotegpscontroller ]] && ruser=$(ls -la /data/data/de.grennith.rgc.remotegpscontroller/ |head -n2 | tail -n1 | awk '{print $3}')
#rgcconf="/data/data/de.grennith.rgc.remotegpscontroller/shared_prefs/de.grennith.rgc.remotegpscontroller_preferences.xml"
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
 aarch64) arch="arm64_v8a";;
 armv8l)  arch="armeabi-v7a";;
esac

checkupdate(){
# $1 = new version
# $2 = installed version
! [[ "$2" ]] && return 0 # for first installs
i=1
#we start at 1 and go until number of . so we can use our counter as awk position
places=$(awk -F. '{print NF+1}' <<< "$1")
while (( "$i" < "$places" )) ;do
 npos=$(awk -v pos=$i -F. '{print $pos}' <<< "$1")
 ipos=$(awk -v pos=$i -F. '{print $pos}' <<< "$2")
 case "$(( $npos - $ipos ))" in
  -*) return 1 ;;
   0) ;;
   *) return 0 ;;
 esac
 i=$((i+1))
 false
done
}

install_atlas(){

# install 55atlas
mount -o remount,rw /system
until /system/bin/curl -s -k -L --fail --show-error -o /system/etc/init.d/55atlas https://raw.githubusercontent.com/dkmur/aconf/master/55atlas || { echo "`date +%Y-%m-%d_%T` Download 55atlas failed, exit script" >> $logfile ; exit 1; } ;do
  sleep 2
done
chmod +x /system/etc/init.d/55atlas
mount -o remount,ro /system
echo "`date +%Y-%m-%d_%T` 55atlas installed" >> $logfile


echo "`date +%Y-%m-%d_%T` we should have installed atlas now :)" >> $logfile
}

update_all(){
echo "`date +%Y-%m-%d_%T` download version file to data/local/temp, check for change and update pogo and/or atlas if needed" >> $logfile
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


for i in "$@" ;do
 case "$i" in
 -ia) install_atlas ;;
 -ua) update_all ;;
# consider adding: downgrade pogo, downgrade atlas, update atlas config file, update donwload link
 esac
done


(( $reboot )) && reboot_device
exit
