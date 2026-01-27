#!/bin/bash

for pkg in $(brew outdated --quiet); do
  if brew reinstall "$pkg" --dry-run 2>&1 | grep -q "sudo"; then
    echo "Skipping $pkg (requires sudo)"
  else
    brew upgrade "$pkg"
  fi
done
