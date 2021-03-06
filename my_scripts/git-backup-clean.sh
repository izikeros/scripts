#!/usr/bin/env bash

git for-each-ref --format="%(refname)" refs/original/ | xargs -rn 1 git update-ref -d
git reflog expire --expire=now --all
git gc --prune=now --aggressive
