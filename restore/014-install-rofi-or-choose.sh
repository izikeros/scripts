#!/usr/bin/env bash
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac


if [ "$machine" == "Linux" ];then
	pacman -S rofi
elif [ "$machine" == "Mac" ];then
	brew install choose
fi
