#!/usr/bin/env bash

# very basic packages that should be installed on any system server or desktop
#  to enable further setup of the system.
# Basic packages list contains typically top-10 most useful packages

./pkg-from-the-list.sh ./pkg/010_basic_cli.txt
#./pkg_from_the_list.py ./pkg/010_basic_cli.txt
echo "### Basic packages installed"
