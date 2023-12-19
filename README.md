# Atlas Configuration Tool

This tool was originally meant to easily convert MAD ATVs to RDM+Atlas devices but has been made more generic over time.  
Today it will/can:
- (still) allows for easy conversion from MAD
- make use of default MAD rom (flash, power on for default installation, via command trigger aconf to finalize installation) 
- default MAD roms have been adjusted, see releases to directly use aconf (flash, insert usb flash drive, power on)
- enable atlas monitor to act upon disturbances
- enable atvdetails sender/receiver to have all version related info, cpu/mem and monitor statistics of atv stored to db
- automatic update of atlas, pogo and scripts

## Setup aconf server side
1. Clone aconf, the directory must be reachable from the web (and kept up-to-date)  
2. It's highly recommended to add basic auth to the aconf directory. For more info see <https://ubiq.co/tech-blog/how-to-password-protect-directory-in-nginx/>  
3. Copy versions.example and atlas_config.json.example and fill out the details. Make sure not to change `"deviceName":"dummy"`, deviceName will either be set to rgc origin in case of MAD atv or it will be set to a temporary name which can be changed in Atlas Dashboard
Some hints for the versions file:
```
atlas_md5                        - the hash of the atlas.apk (In Case the APK changes but version number is still the same)
healthcheck_errors               - true/false - decides if a discord message will be send if a device got many health check errors 
play_integrity                   - true/false - If true, the APK verification will be disabled (needed to install atlas in A9 without manual interaction)
loop_protect_enabled             - true/false - If true, atlas.sh will stop to reboot the device after 20 trys per day
proxy_address                    - ip:port - if set, this address will be configured as system proxy
set_proxy_only_in_same_network   - true/false - If true, only devices with the same subnet will set the proxy (if Proxy_address is 192.168.178.10, only devices with 192.168.178.X will set the proxy)
PIF_module                       - the version of the PlayIntegrityFix Module 
```
4. If you want to skip adding names manually on reflashed devices, copy and fill out mac2name.exmaple file 
5. Add latest atlas version and supported pogo versions to apk folder, make sure to follow naming convention as per example below:  
```
PokemodAtlas-Public-v22050101.apk
pokemongo_arm64-v8a_0.235.0.apk
pokemongo_armeabi-v7a_0.235.0.apk
``` 
6. Add desired PlayIntegrityFix Module to the module folder and put its version in the version file. For the name follow the naming convention of the example


## ATV setup


### 1. Fresh A9 flashed ATV

1. Flash correct rom
2. Let the rom do the initial setup (might take 15min and several reboots)
3. a. If your rom supports an Auto-Setup script use the one provided in jobs folder and rename it if needed
   b. Use ADB to open a shell on the device and paste the commands from the jobs folder
4. The Device should show up in the Atlas Dashboard; activate the license and give it a name
5. The Device should show up in RDM/Flygon


### 2. Existing MAD ATV
an example atlas install job can be found in jobs folder. Adjust url to point to your aconf directory and when used auth settings. Add job to MADmin and execute it. Don't worry if the job is reporting a failure, it's only because it includes a reboot and is taking too much time, but it does run successfully.

`rgc=off` : setting this value to `on` will enable rgc on your devices on next reboot. Please be cautious as if you enable it and have a different version of PoGo in your Madmin packages, you will enter a boot loop as RGC will push the MAD version of the APK while this script will push the one in your directory. The recommendation is to keep if off during your migration, and only enable it when :
- All your devices have been migrated (you don't use MAD anymore).
- Your MAD instances have been restart in config only mode (using -cm).
- You have removed 32bits and 64bits APKs from your Madmin Packages.

### 3. Generic ATV
After initial setup and several reboots push the install of the atlas script manually by connecting to the device using ADB and using the following on command line (update `mydownloadfolder.com`to your own folder location + add your user and password) :

```
su -c 'url_base="https://mydownloadfolder.com" && common_curl_opts="-s -k -L --fail --show-error --user username:password" && mount -o remount,rw / && aconf_versions="/data/local/aconf_versions" && [ ! -e "$aconf_versions" ] && /system/bin/curl $common_curl_opts "$url_base/versions" -o "$aconf_versions" || true && aconf_download="/data/local/aconf_download" && touch "$aconf_download" && echo "url=$url_base" > "$aconf_download" && echo "authUser=username" >> "$aconf_download" && echo "authPass=password" >> "$aconf_download" && /system/bin/curl $common_curl_opts -o /system/bin/atlas.sh "$url_base/scripts/atlas.sh" && chmod +x /system/bin/atlas.sh ; mount -o remount,ro / && /system/bin/atlas.sh -ia'
```

### Logs
Logging and any failure while executing script is logged to the /sdcard/ folder - `aconf.log` & `atlas_monitor.log` can be found there
In case of issues always check there first


## ATVdetails sender/receiver  
Aconf allows to setup for sending ATV information such as pogo/atlas/script versions, ip, atlas settings, atlas/pogo cpu and mem usage to server side receiver which will process to database.  

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
