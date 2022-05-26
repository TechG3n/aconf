# Atlas Configuration Tool

This tool is meant to let you easily convert MAD ATVs (both 32bits and 64bits) to RDM+Atlas devices.

It will also take care of automatically keeping your devices up to date when a new version of Atlas and/or PoGo is required in the future.

To start with it, you first need to create an madmin job that you will push to your devices.

This job needs to contain a path to a directory, freely reachable from the web, and into which you will add all necessary configuration files and APKs.

An example job is provided in the code. Please update it to the URL of your directory.

Don't worry if the job is reporting a failure, it's only because it includes a reboot and is taking too much time, but it does run successfully.

***OPTIONAL BUT HIGHLY RECOMMANDED :***
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
```

The script will automatically check those versions on every reboot of an ATV. If the versions have changed, it will download the corresponding APKs from your above specified folder and will install them automatically.

`rgc=off` : setting this value to `on` will enable rgc on your devices on next reboot. Please be cautious as if you enable it and have a different version of PoGo in your Madmin packages, you will enter a boot loop as RGC will push the MAD version of the APK while this script will push the one in your directory. The recommandation is to keep if off during your migration, and only enable it when :
- All your devices have been migrated (you don't use MAD anymore).
- Your MAD instances have been restart in config only mode (using -cm).
- You have removed 32bits and 64bits APKs from your Madmin Packages.

Logging and any failure while executing script is logged to /sdcard/aconf.log
In case of issues always check there first
