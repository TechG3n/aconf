# Atlas Configuration Tool

This tool is meant to let you easily convert MAD ATVs (both 32bits and 64bits) to RDM+Atlas devices.

It will also take care of automatically keeping your devices up to date when a new version of Atlas and/or PoGo is required in the future.

To start with it, you first need to create an madmin job that you will push to your devices.

This job needs to contain a path to a directory, freely reachable from the web, and into which you will add all necessary configuration files and APKs.

An example job is provided in the code. Please update it to the URL of your directory.

Don't worry if the job is reporting a failure, it's only because it includes a reboot and is taking too much time, but it does run successfully.

***OPTIONAL BUT HIGHLY RECOMMENDED :***
The Job allows you to add an `authUser` and `authPass`. 
Those user and passwords will be used if basic auth has been enabled on your directory.
Please remember this directory contains important information such as your Atlas token or RDM auth.
Refer to this documentation on how to enable basic auth for nginx : https://ubiq.co/tech-blog/how-to-password-protect-directory-in-nginx/


The directory should contain the following files :

- The APK of the latest version of Atlas
- The APK of the 32bits version of PoGo matching your version of Atlas
- The APK of the 64bits version of PoGo matching your version of Atlas
- The Atlas config file (to be described hereunder)
- A version file (to be described hereunder)

Hers is a typical example of directory content :

```
PokemodAtlas-Public-v22050101.apk
pokemongo_arm64-v8a_0.235.0.apk
pokemongo_armeabi-v7a_0.235.0.apk
atlas_config.json
versions
```

Please note the naming convention for the different files, this is important and shouldn't be changed.

Here is the content of the `atlas_config.json` file :

```
{
        "authBearer":"YOUR_RDM_SECRET",
        "deviceAuthToken":"YOUR_ATLAS_AUTH_TOKEN",
        "deviceName":"dummy",
        "email":"YOUR_ATLAS_REGISTRATION_EMAIL",
        "rdmUrl":"http(s)://YOUR_RDM_URL:9001",
        "runOnBoot":true
}
```

Please note that `"deviceName":"dummy"` should not be changed. The script will automatically replace this dummy value with the origin defined in rgc.

Here is the content of the `versions` file :

```
pogo=0.235.0
atlas=v22050101
rgc=off

# Settings for Atlas monitor script
useMonitor=false
monitor_interval=300
update_check_interval=3600
discord_webhook=""
debug=false

# Settings for atvdetails sender
useSender=false
atvdetails_interval=900
atvdetails_receiver_host=""
atvdetails_receiver_port=""
```

Optionally you can also add settings for the types of webhooks you want to receive from the Atlas monitor script.
By default all types of webhooks will be send to your discord channels but you can decide to disable some of them.
Actions will still occur, this is only stopping the webhook messages to be sent.

```
# Settings for Monitor Webhooks
recreate_atlas_config=true
atlas_died=true
pogo_died=true
device_offline=true
unable_check_status=true
pogo_not_focused=false
```

The script will automatically check those versions on every reboot of an ATV. If the versions have changed, it will download the corresponding APKs from your above specified folder and will install them automatically.

`rgc=off` : setting this value to `on` will enable rgc on your devices on next reboot. Please be cautious as if you enable it and have a different version of PoGo in your Madmin packages, you will enter a boot loop as RGC will push the MAD version of the APK while this script will push the one in your directory. The recommandation is to keep if off during your migration, and only enable it when :
- All your devices have been migrated (you don't use MAD anymore).
- Your MAD instances have been restart in config only mode (using -cm).
- You have removed 32bits and 64bits APKs from your Madmin Packages.

Logging and any failure while executing script is logged to /sdcard/aconf.log
In case of issues always check there first

## ***ATVdetails sender/receiver***  
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

- Finally, you can import the dashboards – the `.JSON` files in `aconf/wh_receiver/grafana`. You can do this by selecting, in the Grafana sidebar, `Dashboards -> + Import`. Select, one at a time, the three dashboards to import to Grafana.
  
## ***Using aconf without Madmin***

If you don't run madmin and don't want to run it, you still can push the install of the atlas script manually by connecting to the device using ADB and using the following on command line (update `mydownloadfolder.com`to your own folder location + add your user and password ) :

```
su -c 'file='/data/local/aconf_download' && touch $file  && echo url=https://mydownloadfolder.com > $file  && echo authUser='' >> $file && echo authPass='' >> $file && mount -o remount,rw /system && /system/bin/curl -L -o /system/bin/atlas.sh -k -s https://raw.githubusercontent.com/dkmur/aconf/master/atlas.sh && chmod +x /system/bin/atlas.sh && /system/bin/atlas.sh -ia'
```

