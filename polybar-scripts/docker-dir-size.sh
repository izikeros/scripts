#!/usr/bin/env bash

if [ -d /var/lib/docker ]; then
    docker_dir=$(sudo du -sh /var/lib/docker | awk '{print $1}')
    echo "D: $docker_dir"
fi
