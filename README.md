# Atlas Configuration Tool

This tool was originally meant to easily convert MAD ATVs to RDM+Atlas devices but has been made more generic over time.  
Today it will/can:
- (still) allows for easy convertion from MAD
- make use of default MAD rom (flash, power on for default installation, via command trigger aconf to finalize installation) 
- default MAD roms have been adjusted, see releases to directly use aconf (flash, insert usb flashdrive, power on)
- enable atlas monitor to act upon disturbances
- enable atvdetails sender/receiver to have all version related info, cpu/mem and monitor stastics of atv stored to db
- automatic update of atlas, pogo and scripts

## Setup aconf server side
1. Clone aconf, the directory must be reachable from the web (and kept up-to-date)  
2. It's highly recommended to add basic auth to the aconf directory. For more info see <https://ubiq.co/tech-blog/how-to-password-protect-directory-in-nginx/>  
3. Copy versions.example and atlas_config.json.example and fill out the details. Make sure not to change `"deviceName":"dummy"`, deviceName will either be set to rgc origin in case of MAD atv ot it can be set after installation in atlas backend.  
4. Add latest atlas version and supported pogo versions to apk folder, make sure to follow naming convention as per example below:  
```
PokemodAtlas-Public-v22050101.apk
pokemongo_arm64-v8a_0.235.0.apk
pokemongo_armeabi-v7a_0.235.0.apk
``` 

## ATV setup

### 1. Adjusted MAD rom
1. flash rom <https://github.com/dkmur/aconf/releases>  
2. insert usb flasdrive containing `aconf_info` file (example in folder rom, make sure the file is called exactly that so NOT i.e. `aconf_info.txt`)  
3. power on device and sit back watching you discord channel on progress of installation  

### 2. Existing MAD ATV
an example atlas install job can be found in jobs folder. Adjust url to point to your aconf directory and when used auth settings. Add job to MADmin and execute it. Don't worry if the job is reporting a failure, it's only because it includes a reboot and is taking too much time, but it does run successfully.

`rgc=off` : setting this value to `on` will enable rgc on your devices on next reboot. Please be cautious as if you enable it and have a different version of PoGo in your Madmin packages, you will enter a boot loop as RGC will push the MAD version of the APK while this script will push the one in your directory. The recommandation is to keep if off during your migration, and only enable it when :
- All your devices have been migrated (you don't use MAD anymore).
- Your MAD instances have been restart in config only mode (using -cm).
- You have removed 32bits and 64bits APKs from your Madmin Packages.

### 3. Default MAD rom flashed (no MADmin needed)
After flash power on atv so the mad scripts can install magisk and perform default settings. When that's done, after several reboots push the install of the atlas script manually by connecting to the device using ADB and using the following on command line (update `mydownloadfolder.com`to your own folder location + add your user and password ) :

```
su -c 'file='/data/local/aconf_download' && touch $file && echo url=https://sub.dom.com > $file && echo authUser='username' >> $file && echo authPass='password' >> $file && mount -o remount,rw /system && /system/bin/curl -s -k -L --fail --show-error --user username:password -o /system/bin/atlas.sh https://sub.dom.com/scripts/atlas.sh && chmod +x /system/bin/atlas.sh && mount -o remount,ro /system && /system/bin/atlas.sh -ia'
```

### Logs
Logging and any failure while executing script is logged to /sdcard/aconf.log
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
- Ajust versions file settings for atvdetails sender
- Execute /system/bin/atlas.sh to update to latest version, add webhook sender and start it

3. Grafana Installation:
- To visualise the ATV information sent from aconf, set up Grafana.
- More information here: https://grafana.com/grafana/download and https://grafana.com/docs/grafana/next/setup-grafana/installation/debian/#install-from-apt-repository
Default port is 3000 and you can expose Grafana to the web for easy access.

**Note: Docker install can be messy to connect to your stats database so be warned. (If you get this working, please share how so I can add it to readme).**

- In Grafana web interface, create a data source on your stats database (make sure your user can access the database). Click on “Save & test” to check connection.

- Finally, you can import the dashboards (20_atlas_atv_performance.json.default,21_atlas_atvdetails_overview.json.default,22_atlas_device_overview.json.default), they can be found at <https://github.com/dkmur/rdmStats/tree/master/default_files>. You can do this by selecting, in the Grafana sidebar, `Dashboards -> + Import`. Select, one at a time, the three dashboards to import to Grafana.
