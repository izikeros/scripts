#!/usr/bin/env python3
"""
This script installs packages from the list.

Usage:
    python3 pkg_from_the_list.py <file_with_packages>

Example:
    python3 pkg_from_the_list.py ~/dotfiles/pkglist.txt

The file with packages should be in the following format:
    package1
    package2
    package3
    ...

You can also add comments to the file by using the '#' character:
    package1 # this is a comment
    package2 # this is another comment
    ...

The script will ignore empty lines and lines that start with '#'.

The script will try to determine the package manager based on the distro.
Currently, it supports Ubuntu, Arch Linux and macOS. If the distro cannot be
determined, the script will abort.

TODO: The script will also try to update the package list before installing the
      packages. If the package manager is not supported, the script will abort.
"""
import os
import subprocess
import platform


def get_distro_pkg_install_command():
    sys = ""
    if os.path.isfile('/etc/issue'):
        with open('/etc/issue', 'r') as f:
            content = f.read()
        if "Ubuntu" in content:
            sys = "ubuntu"
        elif "Arch" in content or "archlabs" in content:
            sys = "arch"

    if platform.system() == 'Darwin':
        sys = "macOS"

    if sys == "":
        return ""

    cmd = ""
    if sys == "ubuntu":
        subprocess.check_call(['sudo', 'apt-get', 'update', '-qq'])
        cmd = "apt-get install -y"
    elif sys == "arch":
        cmd = "sudo yay -Sy --noconfirm"
    elif sys == "macOS":
        cmd = "brew install"

    return cmd


def install_packages(file_path):
    cmd = get_distro_pkg_install_command()
    if not cmd:
        print("Cannot determine distro and package manager. Aborting.")
        return

    print(f"Using command: {cmd}")

    with open(file_path, 'r') as f:
        lines = f.readlines()

    packages = [line.split('#')[0].strip() for line in lines if line.strip() and not line.startswith('#')]
    print(f"Found {len(packages)} packages on the list:")
    print(' '.join(packages))

    not_installed = []
    for package in packages:
        print(f"--- {package} ---")
        try:
            subprocess.check_call([cmd, package])
        except subprocess.CalledProcessError:
            not_installed.append(package)
        print()

    if not_installed:
        print("==================================")
        print("These packages were not installed:")
        print("==================================")
        print('\n'.join(not_installed))


if __name__ == "__main__":
    import sys

    install_packages(sys.argv[1])
