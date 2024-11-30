#!/usr/bin/env python3

import configparser

def parse_gitconfig(config_file):
    config = configparser.ConfigParser()
    config.read(config_file)

    aliases = {}
    current_alias = None
    for line in config.get("alias", "").splitlines():
        line = line.strip()
        if line.startswith("#"):
            if current_alias:
                aliases[current_alias] = line[2:].strip()
        elif line:
            current_alias = line.split("=")[0].strip()

    return aliases

if __name__ == "__main__":
    gitconfig_file = ".gitconfig"
    aliases = parse_gitconfig(gitconfig_file)

    for alias, description in aliases.items():
        print(f"{alias:<20} {description}")