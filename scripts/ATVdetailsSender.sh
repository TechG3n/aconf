#!/system/bin/sh
# version 1.7.8

source /data/local/aconf_versions
logfile="/sdcard/aconf.log"

#Configs
atlas_conf="/data/local/tmp/atlas_config.json"
atlas_log="/data/local/tmp/atlas.log"
aconf_log="/sdcard/aconf.log"
monitor_log="/sdcard/atlas_monitor.log"

# initial sleep for reboot
sleep 120

while true
  do
    if [ "$useSender" != true ] ;then
      echo "`date +%Y-%m-%d_%T` ATVdetailsSender: sender stopped" >> $logfile && exit 1
    fi

# remove windows line ending
    dos2unix $atlas_conf

# generic
    RPL=$(($atvdetails_interval/60))
    deviceName=$(cat $atlas_conf | tr , '\n' | grep -w 'deviceName' | awk -F ":" '{ print $2 }' | tr -d \"})
    arch=$(uname -m)
    productmodel=$(getprop ro.product.model)
    atlasSh=$(head -2 /system/bin/atlas.sh | grep '# version' | awk '{ print $NF }')
    atlas55=$([ -f /system/etc/init.d/55atlas ] && head -2 /system/etc/init.d/55atlas | grep '# version' | awk '{ print $NF }' || echo 'na')
    atlas42=$([ -f /system/etc/init.d/42atlas ] && head -2 /system/etc/init.d/42atlas | grep '# version' | awk '{ print $NF }' || echo 'na')
    monitor=$([ -f /system/bin/atlas_monitor.sh ] && head -2 /system/bin/atlas_monitor.sh | grep '# version' | awk '{ print $NF }' || echo 'na')
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
    playstore=$(dumpsys package com.android.vending | grep versionName | head -n 1 | cut -d "=" -f 2 | cut -d " " -f 1)
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
    rdmUrl=$(cat $atlas_conf | tr , '\n' | grep -w 'rdmUrl' | awk -F "\"" '{ print $4 }')
    onBoot=$(cat $atlas_conf | tr , '\n' | grep -w 'runOnBoot' | awk -F ":" '{ print $2 }' | tr -d \"})
# atlas.log
    a_pogoStarted=$(grep 'Launched Pokemon Go' $atlas_log | wc -l)
    a_injection=$(grep 'Injected successfully' $atlas_log | wc -l)
    a_ptcLogin=$(grep 'Logged in using ptc' $atlas_log | wc -l)
    a_atlasCrash=$(grep 'Agent has crashed or stopped responding' $atlas_log | wc -l)
    a_rdmError=$(grep 'Could not send heartbeat' $atlas_log | wc -l)

# monitor.log
    m_noInternet=$(grep 'No internet' $monitor_log | wc -l)
    m_noConfig=$(grep 'atlas_config.json does not exist or is empty' $monitor_log | wc -l)
    m_noLicense=$(grep 'Device Lost Atlas License' $monitor_log | wc -l)
    m_atlasDied=$(grep 'Atlas must be dead, rebooting device' $monitor_log | wc -l)
    m_pogoDied=$(grep 'Pogo must be dead, rebooting device' $monitor_log | wc -l)
    m_deviceOffline=$(grep 'Device must be offline. Running a stop mapping service of Atlas, killing pogo and clearing junk' $monitor_log | wc -l)
    m_noRDM=$(grep 'something wrong with RDM' $monitor_log | wc -l)
    m_noFocus=$(grep 'Something is not right! Pogo is not in focus. Killing pogo and clearing junk' $monitor_log | wc -l)
    m_unknown=$(grep 'Something happened! Some kind of error' $monitor_log | wc -l)

# corrections
[[ -z $temperature ]] && temperature=0
[[ -z $cpuPogoPct ]] && cpuPogoPct=0
[[ -z $cpuApct ]] && cpuApct=0

#send data
    curl -k -X POST ${atvdetails_receiver_user:+-u $atvdetails_receiver_user:$atvdetails_receiver_pass} ${atvdetails_receiver_host}${atvdetails_receiver_port:+:$atvdetails_receiver_port}/webhook -H "Accept: application/json" -H "Content-Type: application/json" --data-binary @- <<DATA
{
    "WHType": "ATVDetails",

    "RPL": "${RPL}",
    "deviceName": "${deviceName}",
    "arch": "${arch}",
    "productmodel": "${productmodel}",
    "atlasSh": "${atlasSh}",
    "atlas55": "${atlas55}",
    "atlas42": "${atlas42}",
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
    "playstore": "${playstore}",

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
    "onBoot": "${onBoot}",

    "a_pogoStarted": "${a_pogoStarted}",
    "a_injection": "${a_injection}",
    "a_ptcLogin": "${a_ptcLogin}",
    "a_atlasCrash": "${a_atlasCrash}",
    "a_rdmError": "${a_rdmError}",

    "m_noInternet": "${m_noInternet}",
    "m_noConfig": "${m_noConfig}",
    "m_noLicense": "${m_noLicense}",
    "m_atlasDied": "${m_atlasDied}",
    "m_pogoDied": "${m_pogoDied}",
    "m_deviceOffline": "${m_deviceOffline}",
    "m_noRDM": "${m_noRDM}",
    "m_noFocus": "${m_noFocus}",
    "m_unknown": "${m_unknown}"
}
DATA

    sleep $atvdetails_interval
  done;
