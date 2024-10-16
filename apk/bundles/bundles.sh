#!/bin/bash

# Base URL for the download
download_url="https://mirror.unownhash.com/apks"

output_dir="$(dirname $(pwd))"
module_dir="${output_dir%/*}/modules"

if [[ -n "$download_url" ]]; then
    read -p "Do you want to download the APK files from download_url? (y/n): " download_choice
    if [[ "$download_choice" =~ ^(y|Y|Yes|yes)$ ]]; then
        rm *.apkm 2>/dev/null
        rm -r META-INF
        read -p "Which version do you want to download? (e.g., 0.329.1): " version
        read -p "Do you also want the cosmog lib? (y/n): " coslib

        url_v8a="${download_url}/com.nianticlabs.pokemongo_arm64-v8a_${version}.apkm"
        url_v7a="${download_url}/com.nianticlabs.pokemongo_armeabi-v7a_${version}.apkm"

        echo "Downloading ${url_v8a}..."
        until wget -q -O "com.nianticlabs.pokemongo_arm64-v8a_${version}.apkm" "$url_v8a" || echo "Couldn't finde that version" ;do
            sleep 2
        done

        echo "Downloading ${url_v7a}..."
        until wget -q -O "com.nianticlabs.pokemongo_armeabi-v7a_${version}.apkm" "$url_v7a" || echo "Couldn't finde that version" ;do
            sleep 2
        done
    fi
else
    echo "No download URL provided. Skipping download."
fi

file_v8a=$(ls *v8a*.apkm 2>/dev/null | grep -v "base\|split")
file_v7a=$(ls *v7a*.apkm 2>/dev/null | grep -v "base\|split")

# Extract the version number (from file_v8a)
version=$(echo $file_v8a | grep -oP '(?<=_)[0-9]+\.[0-9]+\.[0-9]+')

# Check if the v8a file exists
if [[ -f "$file_v8a" ]]; then
    echo "Unzipping and renaming $file_v8a"
    unzip -o $file_v8a 1>/dev/null
    mv base.apk pokemongo_arm64-v8a_${version}_base.apk
    mv split_config.arm64_v8a.apk pokemongo_arm64-v8a_${version}_split.apk
    #extract cosmog lib
    if [[ $coslib == "y" ]]; then
        unzip -o pokemongo_arm64-v8a_${version}_split.apk 1>/dev/null
        mv lib/arm64-v8a/libNianticLabsPlugin.so "$module_dir/libNianticLabsPlugin.so_${version}"
    fi
    # Move the final files to the target directory
    mv pokemongo_arm64-v8a_${version}_*.apk "$output_dir/"
    # Delete all files that are not the script itself
    #find . -type f ! -name "*.sh" -exec rm -rf {} +
else
    echo "File $file_v8a not found. Skipping."
fi

# Check if the v7a file exists
if [[ -f "$file_v7a" ]]; then
    echo "Unzipping and renaming $file_v7a"
    unzip -o $file_v7a 1>/dev/null
    mv base.apk pokemongo_armeabi-v7a_${version}_base.apk
    mv split_config.armeabi_v7a.apk pokemongo_armeabi-v7a_${version}_split.apk
    #extract cosmog lib
    #if [[ $coslib == "y" ]]; then
    #    unzip -o pokemongo_armeabi-v7a_${version}_split.apk 1>/dev/null
    #    mv lib/armeabi-v7a/libNianticLabsPlugin.so "$module_dir/libNianticLabsPlugin.so_${version}"
    #fi
    # Move the final files to the target directory
    mv pokemongo_armeabi-v7a_${version}_*.apk "$output_dir/"
    # Delete all files that are not the script itself
    find . -type f ! -name "*.sh" -exec rm -rf {} +
else
    echo "File $file_v7a not found. Skipping."
fi

echo "Done! Files have been moved to $output_dir."
