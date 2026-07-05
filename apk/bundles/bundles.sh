#!/bin/bash
# version 0.8

# --- CONFIGURATION ---
download_url="https://mirror.unownhash.com/apks"
cosmog_provider_url="https://meow.sylvie.fyi/static/cosmog2.zip"
aegis_provider_url="https://discovery.pokemod.dev/dl/mapping/aegis"

# --- PATH SETUP ---
script_path="$(readlink -f "$0")"
script_dir="$(dirname "$script_path")"
cd "$script_dir" || { echo "Failed to change directory to the script's location."; exit 1; }

output_dir="$(dirname "$script_dir")"
module_dir="${output_dir%/*}/modules"
version_file="$(dirname "$output_dir")/versions"

# --- FUNCTIONS ---

# Show main menu
show_menu() {
    clear
    echo "=============================="
    echo "   UnownHash Download Script  "
    echo "=============================="
    echo "1) Download pogo"
    echo "2) Download cosmog"
    echo "3) Download aegis"
    echo "4) Exit"
    echo "------------------------------"
    read -p "Please select an option [1-4]: " choice
}

# Download pogo
download_pogo() {
    echo "Starting pogo download..."
    rm *.apkm 2>/dev/null
    rm -r META-INF 2>/dev/null

    NewestVersion=$(curl -s "https://mirror.unownhash.com/index.html" | grep -oP 'com\.nianticlabs\.pokemongo_arm64-v8a_\K[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -n 1)

    if [[ -n "$NewestVersion" ]]; then
        read -p "Download the newest version ($NewestVersion)? [Y/n]: " confirmNewest
        if [[ "$confirmNewest" =~ ^(Y|y|Yes|yes)?$ ]]; then
            version="$NewestVersion"
        else
            read -p "Enter version to download (e.g. 0.329.1): " version
        fi
    else
        read -p "Enter version to download (e.g. 0.329.1): " version
    fi

    read -p "Also download pogo lib? (y/n): " pogolib
    pogolib=${pogolib:-n}

    url_v8a="${download_url}/com.nianticlabs.pokemongo_arm64-v8a_${version}.apkm"

    echo "Downloading ${url_v8a}..."
    if ! wget -q -O "com.nianticlabs.pokemongo_arm64-v8a_${version}.apkm" "$url_v8a"; then
        echo "Download failed or version not found."
        return
    fi

    file_v8a=$(ls *v8a*.apkm 2>/dev/null | grep -v "base\|split")

    if [[ -f "$file_v8a" ]]; then
        echo "Unzipping $file_v8a..."
        unzip -o "$file_v8a" >/dev/null
        mv base.apk pokemongo_arm64-v8a_${version}_base.apk
        mv split_config.arm64_v8a.apk pokemongo_arm64-v8a_${version}_split.apk

        if [[ "$pogolib" =~ ^(y|Y|Yes|yes)$ ]]; then
            unzip -o pokemongo_arm64-v8a_${version}_split.apk >/dev/null
            mv lib/arm64-v8a/libNianticLabsPlugin.so "$module_dir/libNianticLabsPlugin.so_${version}"
        fi

        mv pokemongo_arm64-v8a_${version}_*.apk "$output_dir/"
        echo "pogo $version downloaded successfully."
    else
        echo "Error: file $file_v8a not found."
    fi

    read -p "Update version file? (y/n): " update_version
    if [[ "$update_version" =~ ^(y|Y|Yes|yes)$ ]]; then
        sed -i "s/^pogo=.*/pogo=$version/" "$version_file"
        if [[ "$pogolib" =~ ^(y|Y|Yes|yes)$ ]]; then
            sed -i "s/^pogo_libVerion=.*/pogo_libVerion=\"$version\"/" "$version_file"
        fi
        echo "Version file updated."
    fi
}

# Download cosmog
download_cosmog() {
    echo "Starting cosmog download..."
    read -r -p "Download cosmog from sylvie.fyi? [y/N]: " use_provider
    if [[ "$use_provider" =~ ^(Y|y|Yes|yes)$ ]]; then
        cosmog_url="$cosmog_provider_url"
    else
        read -r -p "Enter the download link for the cosmog ZIP file: " cosmog_url
    fi

    if [[ ! "$cosmog_url" =~ \.zip ]]; then
        echo "No ZIP link detected, aborting."
        return
    fi

    if [[ "$cosmog_url" == "$cosmog_provider_url" ]]; then
        read -r -p "Enter the cosmog version (e.g. 2.1.3): " cosmog_version
    fi

    cosmog_zipfile=$(basename "${cosmog_url%%\?*}")

    echo "Downloading $cosmog_zipfile..."
    if ! wget -O "$cosmog_zipfile" "$cosmog_url"; then
        echo "Cosmog ZIP download failed."
        return
    fi

    if [[ -z "$cosmog_version" && "$cosmog_zipfile" =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        cosmog_version="${BASH_REMATCH[1]}"
    fi

    if [[ -z "$cosmog_version" ]]; then
        read -r -p "No version found. Please enter manually (e.g. 2.1.3): " cosmog_version
    fi

    unzip -o "$cosmog_zipfile" >/dev/null

    if [[ -f lib/libart.so ]]; then
        mv -f "lib/libart.so" "$module_dir/libart.so_${cosmog_version}"
        echo "libart.so → $module_dir/libart.so_${cosmog_version}"
    else
        echo "lib/libart.so not found!"
    fi

    if [[ -f com.nianticlabs.pokemongo ]]; then
        mv -f "com.nianticlabs.pokemongo" "$output_dir/com.nianticlabs.pokemongo-${cosmog_version}.bin"
        echo "com.nianticlabs.pokemongo → $output_dir/com.nianticlabs.pokemongo-${cosmog_version}.bin"
    else
        echo "com.nianticlabs.pokemongo not found!"
    fi

    read -p "Update version file? (y/n): " update_version
    if [[ "$update_version" =~ ^(y|Y|Yes|yes)$ ]]; then
        sed -i "s/^cosmog=.*/cosmog=$cosmog_version/" "$version_file"
        echo "Cosmog version updated in $version_file."
    fi
}

# Download aegis
download_aegis() {
    echo "Starting aegis download..."

    # follow 302 to get filename

    aegis_final_url=$(curl -sL -o /dev/null -w '%{url_effective}' -H "Range: bytes=0-0" "$aegis_provider_url")
    aegis_file=$(basename "${aegis_final_url%%\?*}")

    echo "Downloading $aegis_file..."
    if ! curl -sL -o "$aegis_file" "$aegis_provider_url"; then
        echo "Aegis download failed."
        return
    fi

    if [[ ! -s "$aegis_file" ]]; then
        echo "Error: downloaded aegis file is empty or missing."
        return
    fi

    # Pokemod_Aegis_Public_v26032301-6QxfNJDRW7A9.apk
    if [[ "$aegis_file" =~ _(v[0-9]+)- ]]; then
        aversion="${BASH_REMATCH[1]}"
    else
        read -r -p "No version found. Please enter manually (e.g. v26032301): " aversion
    fi

    new_name="PokemodAegis-Public-${aversion}.apk"
    mv -f "$aegis_file" "$output_dir/$new_name"
    echo "$aegis_file → $output_dir/$new_name"

    read -p "Update version file? (y/n): " update_version
    if [[ "$update_version" =~ ^(y|Y|Yes|yes)$ ]]; then
        sed -i "s/^aegis=.*/aegis=$aversion/" "$version_file"
        echo "Aegis version updated in $version_file."
    fi
}

# --- MAIN ---
show_menu

case $choice in
    1) download_pogo ;;
    2) download_cosmog ;;
    3) download_aegis ;;
    4) echo "Exiting script."; exit 0 ;;
    *) echo "Invalid selection." ;;
esac

echo "Cleaning up temporary files..."
find . -type f ! -name "*.sh" -exec rm -f {} +

echo "Done!"