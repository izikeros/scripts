#!/usr/bin/env bash
# usage: ./pkg-from-the-list.sh packages_list.txt

# 0. preprocess packages list
# 1. install generic packages
# 2. install system specific packages
# 3. if Arch install yaourt packages
# 4. if ubuntu install from ppa

#source $HOME/dotfiles/bootstrap/restore/get_distro_pkg_install_command.sh

# ---- Preprocess packages list: ----
# TODO: ignore comments
#   1. lines starting with #
#   2. everything after #

# TODO: support different package names for different systems
# e.g. grep list and create separate files with packages specific for ubuntu
# and arch, split arch to pacman and yaourt lists:




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
# i (inset text) was used on Linux - not sure if still needed
# sed -e "s/#.*$//gi" -e "/^$/d" "$1" > $TMP_FILE
sed -e "s/#.*$//g" -e "/^$/d" "$1" > $TMP_FILE
N=$(wc -l "$TMP_FILE")

echo "Found $N packages on the list:"
while read -r package;
do
    echo -ne "$package "
done < $TMP_FILE
echo

if [[ $OSTYPE == 'darwin'* ]]; then
	# Simplified installation for macOS
	# missing information on packages not installed
	brew install $(cat $TMP_FILE)
else
	# FIXME: for mac os installation stops after each installed package
	# need to run script as many times as the lenght of the list of packages
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


