#!/usr/bin/env bash
# Return proper command for package installation on Ubuntu or Arch linux

# Arch linux ultimate installer
# https://github.com/helmuthdu/aui/blob/master/sharedfuncs

# --- Determine operating system ------
SYS=""
if [[ -f /etc/issue ]]; then
    grep -q  "Ubuntu" /etc/issue && SYS="ubuntu"
    grep -q  "Arch\|archlabs" /etc/issue && SYS="arch"
fi

if [[ $OSTYPE == 'darwin'* ]]; then
  SYS="macOS"
fi

if [ "$SYS" == "" ]; then
    #echo "No known system (Ubuntu|Arch) detected"
    exit 1
fi

# --- Use proper package manager install command ----
if [ "$SYS" == "ubuntu" ]; then
    #echo "-- Ubuntu Linux detected, using apt-get"
    #echo "-- Updating repo list"
    sudo apt-get update -qq
    CMD="apt-get install -y"
fi

if [ "$SYS" == "arch" ]; then
    #echo "Arch Linux detected, using pacman"
    CMD="sudo pacman -Sy --noconfirm"
fi

if [[ "$SYS" == "macOS" ]]; then
  CMD="brew install"
fi


echo "$CMD"
