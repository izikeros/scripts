#!/usr/bin/env bash
# author: Krystian Safjan (ksafjan@gmail.com)
# Licence MIT

set -e

git config user.email "krystian.safjan@gds.ey.com"
git config user.name "Krystian Safjan"

git config gpg.format ssh
git config gpg.ssh.allowedSignersFile ~/.config/git/allowed_ssh_signers
git config user.signingKey ~/.ssh/ey_azure_devops_rsa.pub
git config commit.sign true

