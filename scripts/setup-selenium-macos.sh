#!/bin/bash

SELENIUM_DIR="$HOME/selenium"
JAR_NAME="selenium-server-latest.jar"
DOWNLOAD_API="https://api.github.com/repos/SeleniumHQ/selenium/releases/latest"

mkdir -p "$SELENIUM_DIR"

JAR_PATH="$SELENIUM_DIR/$JAR_NAME"
VERSION_FILE="$SELENIUM_DIR/selenium-version.txt"

latest_version=$(curl -s $DOWNLOAD_API | grep -oP '"tag_name": "\Kselenium-\d+\.\d+\.\d+' | cut -d- -f2)
download_url="https://github.com/SeleniumHQ/selenium/releases/download/selenium-$latest_version/selenium-server-$latest_version.jar"

echo "Latest Selenium version: $latest_version"

current_version=""
if [ -f "$VERSION_FILE" ]; then
    current_version=$(cat "$VERSION_FILE")
fi

update_required=true
if [ -n "$current_version" ]; then
    if [ "$(printf '%s\n' "$latest_version" "$current_version" | sort -V | head -n1)" = "$latest_version" ]; then
        echo "Selenium server is already up to date (version $current_version)"
        update_required=false
    else
        echo "Newer version available: $latest_version (current: $current_version)"
    fi
fi

if [ "$update_required" = true ]; then
    pids=$(pgrep -f "java.*$JAR_NAME")
    if [ -n "$pids" ]; then
        echo "Stopping running Selenium server..."
        kill -9 $pids
        sleep 5
    fi

    [ -f "$JAR_PATH" ] && rm -f "$JAR_PATH"

    echo "Downloading Selenium server..."
    if ! curl -L "$download_url" -o "$JAR_PATH"; then
        echo "Error downloading Selenium server JAR"
        exit 1
    fi
    echo "$latest_version" > "$VERSION_FILE"
fi

echo "Starting Selenium server in background..."

if [ "$SELENIUM_HUB" = "true" ]; then
    echo "Starting in hub mode..."
    nohup java -jar "$JAR_PATH" hub > /dev/null 2>&1 &
elif [ -n "$SELENIUM_HUB_URL" ]; then
    echo "Starting as node and registering with hub: $SELENIUM_HUB_URL"
    nohup java -jar "$JAR_PATH" node --hub "$SELENIUM_HUB_URL" --selenium-manager true > /dev/null 2>&1 &
else
    echo "Starting in standalone mode"
    nohup java -jar "$JAR_PATH" standalone > /dev/null 2>&1 &
fi

echo "Selenium server started"