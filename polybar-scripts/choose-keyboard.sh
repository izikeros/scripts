#!/usr/bin/env bash
rofi -dmenu -i -p "Choose keyboard:" -no-custom -width 30 -lines 2 < ~/.config/keyboards_list | xargs setxkbmap -model microsoft4000 -layout
#                 ANS="$(rofi -sep "|" -dmenu -i -p 'System' -width 20 \
#                    -hide-scrollbar -line-padding 4 -padding 20 \
#                    -lines 4 <<< " Shutdown| Suspend| Lock| Reboot|")"
