#!/bin/bash

# Base URL for the download
#download_url="https://abc.com/apks"

output_dir="$(dirname $(pwd))"

if [[ -n "$download_url" ]]; then
    read -p "Do you want to download the APK files from download_url? (y/n): " download_choice
    if [[ "$download_choice" =~ ^(y|Y|Yes|yes)$ ]]; then
        rm *.apk
        read -p "Which version do you want to download? (e.g., 0.319.0): " version

        url_v8a="${download_url}/com.nianticlabs.pokemongo_arm64-v8a_${version}.apk"
        url_v7a="${download_url}/com.nianticlabs.pokemongo_armeabi-v7a_${version}.apk"

        echo "Downloading ${url_v8a}..."
        wget -q -O "com.nianticlabs.pokemongo_arm64-v8a_${version}.apk" "$url_v8a" || echo "Couldn't finde that version"

        echo "Downloading ${url_v7a}..."
        wget -q -O "com.nianticlabs.pokemongo_armeabi-v7a_${version}.apk" "$url_v7a" || echo "Couldn't finde that version"
    fi
else
    echo "No download URL provided. Skipping download."
fi

file_v8a=$(ls *v8a*.apk 2>/dev/null | grep -v "base\|split")
file_v7a=$(ls *v7a*.apk 2>/dev/null | grep -v "base\|split")

# Extract the version number (from file_v8a)
version=$(echo $file_v8a | grep -oP '(?<=_)[0-9]+\.[0-9]+\.[0-9]+')

# Check if the v8a file exists
if [[ -f "$file_v8a" ]]; then
    echo "Unzipping and renaming $file_v8a"
    unzip $file_v8a 1>/dev/null
    mv base.apk pokemongo_arm64_v8a_${version}_base.apk
    mv split_config.arm64_v8a.apk pokemongo_arm64_v8a_${version}_split.apk
    # Move the final files to the target directory
    mv pokemongo_arm64_v8a_${version}_*.apk "$output_dir/"
    # Delete all files that are not .apk
    find . -type f ! -name "*.apk" ! -name "*.sh" -exec rm -rf {} +
else
    echo "File $file_v8a not found. Skipping."
fi

# Check if the v7a file exists
if [[ -f "$file_v7a" ]]; then
    echo "Unzipping and renaming $file_v7a"
    unzip $file_v7a 1>/dev/null
    mv base.apk pokemongo_armeabi_v7a_${version}_base.apk
    mv split_config.armeabi_v7a.apk pokemongo_armeabi_v7a_${version}_split.apk
    # Move the final files to the target directory
    mv pokemongo_armeabi_v7a_${version}_*.apk "$output_dir/"
    # Delete all files that are not .apk
    find . -type f ! -name "*.apk" ! -name "*.sh" -exec rm -rf {} +
else
    echo "File $file_v7a not found. Skipping."
fi

echo "Done! Files have been moved to $output_dir."