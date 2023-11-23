#!/usr/bin/env bash
# usage: ./pkg-from-the-list.sh packages_list.txt

# 1. install generic packages
# 2. install packages from the list using system-specific package manager
#   - if Arch install yaourt packages
#   - if Ubuntu install from ppa
#   - if macOS install from brew

# TODO: support different package names for different systems
# e.g. grep list and create separate files with packages specific for ubuntu
# and arch, split arch to pacman and yaourt lists:
# support syntax:
#   double-commander, archlinux:doublecmd, macos:doublecommander
# explanation of the example above:
#   default: double-commander
#   archlinux: doublecmd
#   macos: doublecommander
# We would rather need python for that

# Get system and install command
CMD=$("$HOME/scripts/restore/get-distro-pkg-install-command.sh")

if [ -z "${CMD}" ]; then
    echo "Cannot determine distro and package manager. Aborting."
    exit 1
else
    echo "Using command: $CMD"
fi

# prepare clean list of packages - remove comments with package description or commented packages
TMP_FILE=/tmp/install_list.txt

# remove `#` and everything after it
sed -e "s/#.*$//g" -e "/^$/d" "$1" > $TMP_FILE
# sed -e "s/#.*$//gi" -e "/^$/d" "$1" > $TMP_FILE
# i (inset text) was used on Linux - not sure if still needed

N=$(wc -l "$TMP_FILE")

echo "Found $N packages on the list:"
while read -r package;
do
    echo -ne "$package "
done < $TMP_FILE
echo

if [[ $OSTYPE == 'darwin'* ]]; then
	# Install packages one by one, skip errors during installation
  while read -r package;
  do
    echo "--- $package ---"
    $CMD "$package"
    echo ""
  done < $TMP_FILE

else
	# FIXME: for macos installation stops after each installed package
	# need to run script as many times as the length of the list of packages
	NOT_INSTALLED=()
	while read -r package;
	do
		echo "--- $package ---"
		if $CMD "$package"; then
			echo ""
		else
			NOT_INSTALLED+=("$package")
		fi
		echo ""
	done < $TMP_FILE
	echo "=================================="
	echo "These packages were not installed:"
	echo "=================================="
	printf '%s\n' "${NOT_INSTALLED[@]}"
fi
rm $TMP_FILE
