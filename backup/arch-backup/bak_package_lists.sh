#!/usr/bin/env bash

bd="$HOME/_backup_packages_lists"
mkdir -p "$bd"
pacman -Qqe > $bd/pacman_Qqe.lst
pacman -Qqm > $bd/pacman_Qqm.lst
pacman -Qqet > $bd/pacman_Qqet.lst
# pacman -Qqg base > $bd/pacman_Qqg_base.lst
pacman -Qm > $bd/pacman_Qm.lst

pacman -Qqe | grep -v "$(pacman -Qqm)" > $bd/pacman_Qqe-Qqm.lst
# pacman -Qqet | grep -v "$(pacman -Qqg base)" | grep -v "$(pacman -Qqm)" > $bd/pacman_Qqe-Qqg_base-Qqm.lst
pacman -Qm > $bd/pacman_Qm.lst

pip list > $bd/pip.txt