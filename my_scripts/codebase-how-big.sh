#!/usr/bin/env bash

echo "Codebase size:"
echo "=============="
pygount --format=summary . | grep -E --color=never "Python|Language"

echo
echo "Number of classes:"
echo "=================="
find . -type f -name "*.py" -not -path "*.tox/*" -print0 | xargs -0 grep -ch "^[[:blank:]]*class.*:" | awk -F":" '{print $(NF)}' | awk '{sum+=$1;} END{print sum;}'

echo
echo "Number of functions:"
echo "===================="
find . -type f -name "*.py" -not -path "*.tox/*" -print0 | xargs -0 grep -ch "^[[:blank:]]*def.*:" | mawk -F":" '{print $(NF)}' | awk '{sum+=$1;} END{print sum;}'
