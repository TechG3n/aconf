#!/system/bin/sh
# version 1.2

source /data/local/aconf_versions
logfile="/sdcard/aconf.log"

#Configs
atlas_conf="/data/local/tmp/atlas_config.json"
atlas_log="/data/local/tmp/atlas.log"
aconf_log="/sdcard/aconf.log"
monitor_log="/sdcard/atlas_monitor.log"

while true
  do
    if [ "$useSender" != true ] ;then
      echo "`date +%Y-%m-%d_%T` ATVdetailsSender: sender stopped" >> $logfile && exit 1
    fi

# generic
    RPL=$(($atvdetails_interval/60))
    deviceName=$(cat $atlas_conf | tr , '\n' | grep -w 'deviceName' | awk -F ":" '{ print $2 }' | tr -d \"})
    arch=$(uname -m)
    productmodel=$(getprop ro.product.model)
    atlasSh=$(head -2 /system/bin/atlas.sh | grep '# version' | awk '{ print $NF }')
    atlas55=$(head -2 /system/etc/init.d/55atlas | grep '# version' | awk '{ print $NF }' || echo 'na')
    monitor=$(head -2 /system/bin/atlas_monitor.sh | grep '# version' | awk '{ print $NF }')
    whversion=$([ -f /system/bin/ATVdetailsSender.sh ] && head -2 /system/bin/ATVdetailsSender.sh | grep '# version' | awk '{ print $NF }' || echo 'na')
    pogo=$(dumpsys package com.nianticlabs.pokemongo | grep versionName | head -n1 | sed 's/ *versionName=//')
    atlas=$(dumpsys package com.pokemod.atlas | grep versionName | head -n1 | sed 's/ *versionName=//')
    temperature=$(cat /sys/class/thermal/thermal_zone0/temp | cut -c -2)
    magisk=$(magisk -c | sed 's/:.*//')
    magisk_modules=$(ls -1 /sbin/.magisk/img | xargs | sed -e 's/ /, /g' 2>/dev/null)
    macw=$([ -d /sys/class/net/wlan0 ] && ifconfig wlan0 |grep 'HWaddr' |awk '{ print ($NF) }' || echo 'na')
    mace=$(ifconfig eth0 |grep 'HWaddr' |awk '{ print ($NF) }')
    ip=$(ifconfig wlan0 |grep 'inet addr' |cut -d ':' -f2 |cut -d ' ' -f1 && ifconfig eth0 |grep 'inet addr' |cut -d ':' -f2 |cut -d ' ' -f1)
    ext_ip=$(curl -k -s https://ifconfig.me/)
    hostname=$(getprop net.hostname)
# atv performance
    memTot=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
    memFree=$(cat /proc/meminfo | grep MemFree | awk '{print $2}')
    memAv=$(cat /proc/meminfo | grep MemAvailable | awk '{print $2}')
    memPogo=$(dumpsys meminfo 'com.nianticlabs.pokemongo' | grep -m 1 "TOTAL" | awk '{print $2}')
    memAtlas=$(dumpsys meminfo 'com.pokemod.atlas:mapping' | grep -m 1 "TOTAL" | awk '{print $2}')
    cpuSys=$(top -n 1 | grep -m 1 "System" | awk '{print substr($2, 1, length($2)-2)}')
    cpuUser=$(top -n 1 | grep -m 1 "User" | awk '{print substr($2, 1, length($2)-2)}')
    cpuL5=$(dumpsys cpuinfo | grep "Load" | awk '{ print $2 }')
    cpuL10=$(dumpsys cpuinfo | grep "Load" | awk '{ print $4 }')
    cpuL15=$(dumpsys cpuinfo | grep "Load" | awk '{ print $6 }')
    cpuPogoPct=$(dumpsys cpuinfo | grep 'com.nianticlabs.pokemongo' | awk '{print substr($1, 1, length($1)-1)}')
    cpuApct=$(dumpsys cpuinfo | grep 'com.pokemod.atlas' | awk '{print substr($1, 1, length($1)-1)}')
    diskSysPct=$(df -h | grep /sbin/.magisk/mirror/system | awk '{print substr($5, 1, length($5)-1)}')
    diskDataPct=$(df -h | grep /sbin/.magisk/mirror/data | awk '{print substr($5, 1, length($5)-1)}')
    numPogo=$(ls -l /sbin/.magisk/mirror/data/app/ | grep com.nianticlabs.pokemongo | wc -l)
# aconf.log
    reboot=$(grep 'Device rebooted' $aconf_log | wc -l)
# atlas config
    authBearer=$(cat $atlas_conf | tr , '\n' | grep -w 'authBearer' | awk -F ":" '{ print $2 }' | tr -d \"})
    token=$(cat $atlas_conf | tr , '\n' | grep -w 'deviceAuthToken' | awk -F ":" '{ print $2 }' | tr -d \"})
    email=$(cat $atlas_conf | tr , '\n' | grep -w 'email' | awk -F ":" '{ print $2 }' | tr -d \"})
    rdmUrl=$(cat $atlas_conf | tr , '\n' | grep -w 'rdmUrl' | awk -F ":" '{ print $2 }' | tr -d \"})
    onBoot=$(cat $atlas_conf | tr , '\n' | grep -w 'runOnBoot' | awk -F ":" '{ print $2 }' | tr -d \"})
# atlas.log (anything to grep from $atlas_log ?)

# monitor.log (anything to grep from $monitor_log ?)


#send data
    curl -k -X POST $atvdetails_receiver_host:$atvdetails_receiver_port/webhook -H "Accept: application/json" -H "Content-Type: application/json" --data-binary @- <<DATA
{
    "RPL": "${RPL}",
    "deviceName": "${deviceName}",
    "arch": "${arch}",
    "productmodel": "${productmodel}",
    "atlasSh": "${atlasSh}",
    "atlas55": "${atlas55}",
    "monitor": "${monitor}",
    "whversion": "${whversion}",
    "pogo": "${pogo}",
    "atlas": "${atlas}",
    "temperature": "${temperature}",
    "magisk": "${magisk}",
    "magisk_modules": "${magisk_modules}",
    "macw": "${macw}",
    "mace": "${mace}",
    "ip": "${ip}",
    "ext_ip": "${ext_ip}",
    "hostname": "${hostname}",

    "memTot": "${memTot}",
    "memFree": "${memFree}",
    "memAv": "${memAv}",
    "memPogo": "${memPogo}",
    "memAtlas": "${memAtlas}",
    "cpuSys": "${cpuSys}",
    "cpuUser": "${cpuUser}",
    "cpuL5": "${cpuL5}",
    "cpuL10": "${cpuL10}",
    "cpuL15": "${cpuL15}",
    "cpuPogoPct": "${cpuPogoPct}",
    "cpuApct": "${cpuApct}",
    "diskSysPct": "${diskSysPct}",
    "diskDataPct": "${diskDataPct}",
    "numPogo": "${numPogo}",

    "reboot": "${reboot}",

    "authBearer": "${authBearer}",
    "token": "${token}",
    "email": "${email}",
    "rdmUrl": "${rdmUrl}",
    "onBoot": "${onBoot}"
}
DATA

    sleep $atvdetails_interval
  done;
