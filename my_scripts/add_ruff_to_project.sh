#!/usr/bin/env bash
# This script adds ruff config to the project

# function to download a file based on user input
function download_file() {
    local url=$1
    local filename=$2
    curl -sL $url -o $filename
}

download_file https://gist.github.com/izikeros/8cbc53d9fd6c40b38b52bebd718fce37/raw ./ruff.toml
