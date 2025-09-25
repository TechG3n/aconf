#!/bin/bash
# version 0.3

# Base URL for the download
download_url="https://mirror.unownhash.com/apks"

# Determine the absolute path of this script and change directory to its location.
script_path="$(readlink -f "$0")"                 # Get the full path of the script.
script_dir="$(dirname "$script_path")"             # Extract the directory from the script path.
cd "$script_dir" || { echo "Failed to change directory to the script's location."; exit 1; }

output_dir="$(dirname "$script_dir")"
module_dir="${output_dir%/*}/modules"
version_file="$(dirname "$output_dir")/versions"

# Initialize flags to track if v8 files have been processed.
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

        read -p "Do you also want the pogo lib? (y/n): " pogolib
        pogolib=${pogolib:-n}
        read -p "Do you also want the cosmog binary with its lib? (y/n): " cosbin
        cosbin=${cosbin:-n}
        read -p "Do you want to update your versions file to the new versions? (y/n): " version_choice
        version_choice=${version_choice:-n}

        # Construct URLs
        url_v8a="${download_url}/com.nianticlabs.pokemongo_arm64-v8a_${version}.apkm"

        echo "Downloading ${url_v8a}..."
        until wget -q -O "com.nianticlabs.pokemongo_arm64-v8a_${version}.apkm" "$url_v8a" || echo "Couldn't find that version" ;do
            sleep 2
        done

else
    echo "No download URL provided. Exit."
    exit 1
fi

file_v8a=$(ls *v8a*.apkm 2>/dev/null | grep -v "base\|split")

# Extract the version number (from file_v8a)
version=$(echo $file_v8a | grep -oP '(?<=_)[0-9]+\.[0-9]+\.[0-9]+')

# Check if the v8a file exists
if [[ -f "$file_v8a" ]]; then
    echo "Unzipping and renaming $file_v8a"
    unzip -o $file_v8a 1>/dev/null
    mv base.apk pokemongo_arm64-v8a_${version}_base.apk
    mv split_config.arm64_v8a.apk pokemongo_arm64-v8a_${version}_split.apk
    # extract cosmog lib
    if [[ "$pogolib" =~ ^(y|Y|Yes|yes)$ ]]; then
        unzip -o pokemongo_arm64-v8a_${version}_split.apk 1>/dev/null
        mv lib/arm64-v8a/libNianticLabsPlugin.so "$module_dir/libNianticLabsPlugin.so_${version}"
    fi
    # Move the final files to the target directory
    mv pokemongo_arm64-v8a_${version}_*.apk "$output_dir/"
    v8=true
else
    echo "File $file_v8a not found. Skipping."
fi

# download cosmog + lib, rename and move
if [[ "$cosbin" =~ ^(y|Y|Yes|yes)$ ]]; then

    # get download link
    echo "Please enter the download link for the Cosmog ZIP file (Tip: Right click > Copy link in Discord or similar):"
    read cosmog_url

    if [[ ! "$cosmog_url" =~ cosmog.*\.zip ]]; then
        echo "No Cosmog link given, skipping this step."
    else
        # Download the ZIP file
        cosmog_zipfile=$(basename "$cosmog_url")
        echo "Downloading $cosmog_zipfile ..."
        wget -O "$cosmog_zipfile" "$cosmog_url"
        if [[ $? -ne 0 ]]; then
            echo "Cosmog ZIP download failed, skipping next file."
        else
            # Extract version from ZIP name (e.g. 2.1.3)
            cosmog_version=$(echo "$cosmog_zipfile" | grep -oP '\d+\.\d+\.\d+')
            if [[ -z "$cosmog_version" ]]; then
                echo "No version number found!"
            else
                unzip -o "$cosmog_zipfile"
                if [[ -f lib/libart.so ]]; then
                    mv lib/libart.so "$module_dir/libart.so_${cosmog_version}"
                    echo "libart.so moved to $module_dir/libart.so_${cosmog_version}"
                else
                    echo "lib/libart.so not found!"
                fi
                if [[ -f com.nianticlabs.pokemongo ]]; then
                    mv com.nianticlabs.pokemongo "$output_dir/com.nianticlabs.pokemongo-${cosmog_version}.bin"
                    echo "com.nianticlabs.pokemongo moved to $output_dir/com.nianticlabs.pokemongo-${cosmog_version}.bin"
                else
                    echo "com.nianticlabs.pokemongo not found!"
                fi
                if [[ -f $output_dir/com.nianticlabs.pokemongo-${cosmog_version}.bin || -f $module_dir/libart.so_${cosmog_version} || $version_choice =~ ^(y|Y|Yes|yes)$ ]]; then
                    sed -i "s/^cosmog=.*/cosmog=$cosmog_version/" "$version_file"
                fi    
            fi
        fi
    fi

fi

#change versions in version file
if $v8; then
    if [[ "$version_choice" =~ ^(y|Y|Yes|yes)$ ]]; then
        sed -i "s/^pogo=.*/pogo=$version/" "$version_file"
        if [[ "$pogolib" =~ ^(y|Y|Yes|yes)$ ]]; then
            sed -i "s/^cosmog_libVerion=.*/cosmog_libVerion=\"$version\"/" "$version_file"
        fi
        echo "Version file updated."
    fi
fi

# Delete all files that are not the script itself
echo "Cleaning up"
find . -type f ! -name "*.sh" -exec rm -rf {} +

echo "Done! Files have been moved to $output_dir."
