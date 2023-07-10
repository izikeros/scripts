#!/usr/bin/env bash


# function to download a file based on user input
function download_file() {
    local url=$1
    local filename=$2
    read -p "Do you want to add $filename? [y/n]" -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        curl -sL $url -o $filename
    else
        rm -f $filename
    fi
}

# pre-commit install
read -p "Do you want to install pre-commit package and autoupdate? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    pip install pre-commit
    pre-commit autoupdate
fi

# download required files
download_file https://gist.github.com/izikeros/937b05e81b5dca81d3daf309ea6bad20/raw ./.pre-commit-config.yaml
download_file https://gist.github.com/izikeros/4c38eb8ee022eda256a7880ddbd6f834/raw ./.bandit
download_file https://gist.github.com/izikeros/946d65c15190b7cf48590f629119ab60/raw ./mypy.ini
download_file https://gist.github.com/izikeros/c938c49f5ad38dcc74a5671e85f694e7/raw ./.flake8
download_file https://gist.github.com/izikeros/1a2243e083d083c2a4f97cf9c19648d9/raw ./tox.ini
download_file https://gist.github.com/izikeros/4c79e2f82b68083b8a0b23badc36204d/raw ./pytest.ini
download_file https://gist.github.com/izikeros/beac1ca8de132ad527ab27e32a950a11/raw ./requirements-dev.txt
download_file https://gist.github.com/izikeros/87b544d1ba644cc89dccca04fc87d65d/raw ./README.md
# MIT license
