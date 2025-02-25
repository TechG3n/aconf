#!/bin/bash
# version 0.2

# Base URL for the download
download_url="https://mirror.unownhash.com/apks"

# Determine the absolute path of this script and change directory to its location.
script_path="$(readlink -f "$0")"                 # Get the full path of the script.
script_dir="$(dirname "$script_path")"             # Extract the directory from the script path.
cd "$script_dir" || { echo "Failed to change directory to the script's location."; exit 1; }

output_dir="$(dirname "$script_dir")"
module_dir="${output_dir%/*}/modules"
version_file="$(dirname "$output_dir")/versions"

# Initialize flags to track if v7 and v8 files have been processed.
v7=false
v8=false

if [[ -n "$download_url" ]]; then
        rm *.apkm 2>/dev/null
        rm -r META-INF 2>/dev/null

        # Retrieve the newest version
        NewestVersion=$(curl -s "https://mirror.unownhash.com/index.html" | grep -oP 'com\.nianticlabs\.pokemongo_arm64-v8a_\K[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -n 1)

        if [[ -n "$NewestVersion" ]]; then
            read -p "Do you want to download the newest version ($NewestVersion)? [Y/n]: " confirmNewest
            if [[ "$confirmNewest" =~ ^(Y|y|Yes|yes)?$ ]]; then
                version="$NewestVersion"
            else
                read -p "Which version do you want to download? (e.g., 0.329.1): " version
            fi
        else
            read -p "Which version do you want to download? (e.g., 0.329.1): " version
        fi

        read -p "Do you also want the cosmog lib? (y/n): " coslib
        coslib=${coslib:-n}
        read -p "Do you want to update your versions file to the new version? (y/n): " version_choice
        version_choice=${version_choice:-n}

        # Construct URLs
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
else
    echo "No download URL provided. Exit."
    exit 1
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
    if [[ "$coslib" =~ ^(y|Y|Yes|yes)$ ]]; then
        unzip -o pokemongo_arm64-v8a_${version}_split.apk 1>/dev/null
        mv lib/arm64-v8a/libNianticLabsPlugin.so "$module_dir/libNianticLabsPlugin.so_${version}"
    fi
    # Move the final files to the target directory
    mv pokemongo_arm64-v8a_${version}_*.apk "$output_dir/"
    # Delete all files that are not the script itself
    #find . -type f ! -name "*.sh" -exec rm -rf {} +
    v8=true
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
    v7=true
else
    echo "File $file_v7a not found. Skipping."
fi

if $v7 && $v8; then
    if [[ "$version_choice" =~ ^(y|Y|Yes|yes)$ ]]; then
        sed -i "s/^pogo=.*/pogo=$version/" "$version_file"
        if [[ "$coslib" =~ ^(y|Y|Yes|yes)$ ]]; then
            sed -i "s/^cosmog_libVerion=.*/cosmog_libVerion=\"$version\"/" "$version_file"
        fi
        echo "Version file updated."
    fi
fi

echo "Done! Files have been moved to $output_dir."
