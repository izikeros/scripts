#!/usr/bin/env python3

# Module for installing packages from the list written with Github copilot
# License: MIT

import os


def check_if_system_is_macos():
    return (
        os.path.isfile("/etc/os-release") and "macos" in open("/etc/os-release").read()
    )


def determine_operating_system():
    # determine whether operating system is ubuntu/debian, arch linux or macos
    if os.path.isfile("/etc/debian_version"):
        return "debian"
    elif os.path.isfile("/etc/arch-release"):
        return "arch"
    elif os.path.isfile("/etc/os-release"):
        with open("/etc/os-release") as f:
            for line in f:
                if "ID=ubuntu" in line:
                    return "ubuntu"
                elif "ID=arch" in line:
                    return "arch"
                elif "ID=macos" in line:
                    return "macos"
    return "unknown"


# install packages in text file where each line contains a package name. Return list of
# successfully installed packages and list of packages unable to install. Display progressbar
def install_packages(packages_file, operating_system):
    packages_installed = []
    packages_not_installed = []
    if operating_system == "linux":
        packages_installed, packages_not_installed = install_packages_linux(
            packages_file
        )
    elif operating_system == "macos":
        packages_installed, packages_not_installed = install_packages_macos(
            packages_file
        )
    return packages_installed, packages_not_installed


def install_packages_linux(packages_file, package_manager="apt"):
    packages_installed = []
    packages_not_installed = []
    with open(packages_file) as f:
        for line in f:
            package = line.strip()
            if package_manager == "apt":
                if install_package_apt(package):
                    packages_installed.append(package)
                else:
                    packages_not_installed.append(package)
            elif package_manager == "pacman":
                if install_package_pacman(package):
                    packages_installed.append(package)
                else:
                    packages_not_installed.append(package)
            elif package_manager == "brew":
                if install_package_brew(package):
                    packages_installed.append(package)
                else:
                    packages_not_installed.append(package)
            elif package_manager == "yay":
                if install_package_yay(package):
                    packages_installed.append(package)
                else:
                    packages_not_installed.append(package)
    return packages_installed, packages_not_installed


def install_packages_macos(packages_file, package_manager="brew"):
    packages_installed = []
    packages_not_installed = []
    with open(packages_file) as f:
        for line in f:
            package = line.strip()
            if package_manager == "brew":
                if install_package_brew(package):
                    packages_installed.append(package)
                else:
                    packages_not_installed.append(package)
    return packages_installed, packages_not_installed


def install_package_apt(package):
    command = "apt-get install " + package
    return run_command(command)


def install_package_pacman(package):
    command = "pacman -S " + package
    return run_command(command)


def install_package_yay(package):
    command = "yay -S " + package
    return run_command(command)


def install_package_brew(package):
    command = "brew install " + package
    return run_command(command)


def run_command(command):
    print(command)
    os.system(command)
    return True


def __main__():
    operating_system = determine_operating_system()
    packages_installed, packages_not_installed = install_packages(
        "packages.txt", operating_system
    )
    print("Packages installed:")
    print(packages_installed)
    print("Packages not installed:")
    print(packages_not_installed)
