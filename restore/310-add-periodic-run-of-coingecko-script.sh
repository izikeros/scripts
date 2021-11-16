#!/usr/bin/env bash

echo "Add script launcher to cron:"
echo "crontab -e"
echo "*/5 * * * * ~/bin/gecko_fetcher.py"
echo
echo "or as systemd:"
echo ""