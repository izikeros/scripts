#!/usr/bin/env bash

# install chrony
yay -S --answerclean None --answerdiff None chrony

# enable and start service
systemctl enable chronyd
systemctl start chronyd

# chechk status
systemctl status chronyd
timedatectl
