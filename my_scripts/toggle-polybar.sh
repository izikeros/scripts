#!/usr/bin/env bash


if [[ $(pidof polybar) ]]; then
    pkill polybar
else
    #al-polybar-session
    polybar openbox-bar &
fi
