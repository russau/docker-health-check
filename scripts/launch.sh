#!/bin/sh
echo "$(date) Sleeping first"
sleep 30
echo "$(date) Launching server"
/usr/local/bin/node /scripts/echo.js