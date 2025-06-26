#!/bin/bash

pids=$(pgrep -f "java.*selenium-server-latest.jar")

if [ -n "$pids" ]; then
    echo "Stopping Selenium server processes..."
    kill -9 $pids
    echo "All Selenium server processes stopped"
else
    echo "No Selenium server processes found"
fi