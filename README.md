# Multi Mitm Configuration Tool

This tool will help you install your favorite mitm(s) on different ATVs and keep them up2date & running.
Once set up, you don't need ADB/SSH access to the devices. 
- Setup and monitor devices with Atlas, Aegis or cosmog - a mixed setup is possible too
- (still) allows for easy conversion from MAD
- enable a mitm dependend monitor to act upon disturbances
- enable atvdetails sender/receiver to have all version related info, cpu/mem and monitor statistics of atv stored to db
- automatic update of mitm, pogo and scripts

## Setup aconf server side
1. Clone aconf, the directory must be reachable from the web (and kept up-to-date)  
2. It's highly recommended to add basic auth to the aconf directory. For more info see [here](https://ubiq.co/tech-blog/how-to-password-protect-directory-in-nginx/)
3. Copy versions.example and [mitm]_config.json.example and fill out the details.  Make sure to remove 'example' from the file name and do not to change `"deviceName":"dummy"`, deviceName will either be set to rgc origin in case of MAD atv or it will be set to a temporary name which can be changed in Atlas Dashboard

Some hints for the versions file:
```
[mitm]_md5                       - the hash of the [mitm].apk (In Case the APK changes but version number is still the same)
healthcheck_errors               - true/false - decides if a discord message will be send if a device got many health check errors 
play_integrity                   - true/false - If true, the APK verification will be disabled (needed to install apks in A9 without manual interaction)
loop_protect_enabled             - true/false - If true, atlas.sh/aegis.sh will stop to reboot the device after 20 trys per day
proxy_address                    - ip:port - if set, this address will be configured as system proxy. Use "remove" to remove proxy from all devices.
set_proxy_only_in_same_network   - true/false - If true, only devices with the same subnet will set the proxy (if Proxy_address is 192.168.178.10, only devices with 192.168.178.X will set the proxy)
PIF_module                       - the version of the PlayIntegrityFix Module
cosmog_libVerion                 - version of the lib needed by cosmog
```
4. If you want to skip adding names manually on reflashed devices, copy and fill out mac2name.exmaple file 
5. Add latest atlas/aegis/cosmog APK to apk folder, Pogo bundle needs to be unzipped - only base.apk split_config.apk are needed.<br/> Make sure to follow naming convention as per example below:  
```
PokemodAtlas-Public-v22050101.apk
PokemodAegis-Public-v22050101.apk
cosmog-1.2.2.apk
pokemongo_arm64-v8a_0.235.0_base.apk + pokemongo_arm64-v8a_0.235.0_split.apk 
pokemongo_armeabi-v7a_0.235.0_base.apk + pokemongo_armeabi-v7a_0.235.0_split.apk
``` 
6. Add desired PlayIntegrityFix Module and Fingerprint to the module folder and put its version in the version file. For the name follow the naming convention of the example

7. If you want to use cosmog, put the lib file [(get it here)](https://github.com/sy1vi3/joltik.git) in the modules folder and name it `libNianticLabsPlugin.so_0.307.1` (change lib ver if needed) 


## ATV setup


### Install aconf

1. Flash correct rom
2. Let the rom do the initial setup (might take 15min and several reboots)
3. a. If your rom supports an Auto-Setup script use the one provided in jobs folder and rename it if needed
   b. Use ADB to open a shell on the device and paste on of the comands. Replace mydownloadfolder witrh your url and username:password with the correct values.
      For Atlas:
      ```
      su -c 'url_base="https://mydownloadfolder.com" && common_curl_opts="-s -k -L --fail --show-error --user username:password" && mount -o remount,rw / && aconf_versions="/data/local/aconf_versions" && [ ! -e "$aconf_versions" ] && /system/bin/curl $common_curl_opts "$url_base/versions" -o "$aconf_versions" || true && aconf_download="/data/local/aconf_download" && touch "$aconf_download" && echo "url=$url_base" > "$aconf_download" && echo "authUser=username" >> "$aconf_download" && echo "authPass=password" >> "$aconf_download" && /system/bin/curl $common_curl_opts -o /system/bin/atlas.sh "$url_base/scripts/atlas.sh" && chmod +x /system/bin/atlas.sh ; mount -o remount,ro / && /system/bin/atlas.sh -ia'
      ```

      For Aegis:
      ```
      su -c 'url_base="https://mydownloadfolder.com" && common_curl_opts="-s -k -L --fail --show-error --user username:password" && mount -o remount,rw / && aconf_versions="/data/local/aconf_versions" && [ ! -e "$aconf_versions" ] && /system/bin/curl $common_curl_opts "$url_base/versions" -o "$aconf_versions" || true && aconf_download="/data/local/aconf_download" && touch "$aconf_download" && echo "url=$url_base" > "$aconf_download" && echo "authUser=username" >> "$aconf_download" && echo "authPass=password" >> "$aconf_download" && /system/bin/curl $common_curl_opts -o /system/bin/aegis.sh "$url_base/scripts/aegis.sh" && chmod +x /system/bin/aegis.sh ; mount -o remount,ro / && /system/bin/aegis.sh -ia'
      ```

      For Cosmog:
      ```
      su -c 'url_base="https://mydownloadfolder.com" && common_curl_opts="-s -k -L --fail --show-error --user username:password" && mount -o remount,rw / && aconf_versions="/data/local/aconf_versions" && [ ! -e "$aconf_versions" ] && /system/bin/curl $common_curl_opts "$url_base/versions" -o "$aconf_versions" || true && aconf_download="/data/local/aconf_download" && touch "$aconf_download" && echo "url=$url_base" > "$aconf_download" && echo "authUser=username" >> "$aconf_download" && echo "authPass=password" >> "$aconf_download" && /system/bin/curl $common_curl_opts -o /system/bin/cosmog.sh "$url_base/scripts/cosmog.sh" && chmod +x /system/bin/cosmog.sh ; mount -o remount,ro / && /system/bin/cosmog.sh -ia'
      ```
4. The Device should show up in the MTIMs Dashboard; activate the license and give it a name
5. The Device should show up in RDM/Rotom


### Remove aconf
To remove aconf from an ATV - just use this command via ADB:

```
su -c 'mount -o remount,rw / && rm -f /data/local/aconf_download /data/local/aconf_versions /data/local/aconf_mac2name /system/bin/a???s.sh /system/bin/cosmog.sh /system/bin/a???s_new.sh /system/bin/cosmog_new.sh /system/bin/a???s_monitor.sh /system/bin/cosmog_monitor.sh /system/etc/init/55a???s.rc /system/etc/init/55cosmog.rc /system/etc/init/a???s_monitor.rc /system/etc/init/cosmog_monitor.rc /system/etc/init.d/55a???s /system/etc/init.d/55cosmog /sdcard/*_monitor.log /sdcard/aconf.log /sdcard/not_licensed && sync ; mount -o remount,ro / && pgrep -f -L9 /system/bin/ATVdetailsSender.sh && pgrep -f -L9 /system/bin/a???s_monitor.sh'
```

### Logs
Logging and any failure while executing script is logged to the /sdcard/ folder - `aconf.log` & `[MITM]_monitor.log` can be found there - In case of issues always check there first


## ATVdetails sender/receiver  
Aconf allows to setup for sending ATV information such as pogo/mitm/script versions, ip, atlas settings, atlas/pogo cpu and mem usage to server side receiver which will process to database.  

1. Prepare receiver:
- Receiver is located in folder wh_receiver
- Create database and create tables from /sql/tables.sql
- Create a database user and provide permissions to user (make sure not to use `$` in password):
```
grant all privileges on ##STATS_DB##.* to ##MYSELF##@localhost;
flush privileges;
```
- Copy config.ini.example to config.ini and fill out the details
- Start receiver i.e. `pm2 start start_whreceiver.py --name atvdetails --interpreter python3`
- Ensure firewall is not blocking host/port

2. Prepare aconf settings and start sender:
- Adjust versions file settings for atvdetails sender
- Execute /system/bin/atlas.sh to update to latest version, add webhook sender and start it

3. Grafana Installation:
- To visualize the ATV information sent from aconf, set up Grafana.
- More information here: https://grafana.com/grafana/download and https://grafana.com/docs/grafana/next/setup-grafana/installation/debian/#install-from-apt-repository
Default port is 3000 and you can expose Grafana to the web for easy access.

**Note: Docker install can be messy to connect to your stats database so be warned. (If you get this working, please share how so I can add it to readme).**

- In Grafana web interface, create a data source on your stats database (make sure your user can access the database). Click on “Save & test” to check connection.

- Finally, you can import the dashboards (20_atlas_atv_performance.json.default,21_atlas_atvdetails_overview.json.default,22_atlas_device_overview.json.default), they can be found at <https://github.com/dkmur/rdmStats/tree/master/default_files>. You can do this by selecting, in the Grafana sidebar, `Dashboards -> + Import`. Select, one at a time, the three dashboards to import to Grafana.
