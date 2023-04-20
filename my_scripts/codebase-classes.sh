#!/usr/bin/env bash

echo
echo "Classes:"
echo "========"
find . -type f -name "*.py" -not -path "*.tox/*" -print0 | xargs -0 grep -h "^[[:blank:]]*class .*:" | sed 's/://g' | sed 's/^[[:space:]]*//' | sed 's/^class//g'
