#!/usr/bin/env bash

# exit on error
set -e

mv ~/.config/GIMP/2.10 ~/.config/GIMP/2.10.OLD
cd ~/.config/GIMP/
git clone --depth=1 https://github.com/doctormo/GimpPs.git 2.10
