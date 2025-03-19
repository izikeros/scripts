#!/usr/bin/env bash

echo "Codebase size:"
echo "=============="
if ! command -v pygount &> /dev/null
then
	echo "pygount could not be found. Please install it using: pipx install pygount"
	exit 1
fi

pygount --format=summary . | grep -E --color=never "Python|Language"

echo
echo "Number of classes:"
echo "=================="
find . -type d \( -name "venv" -o -name ".venv" -o -name ".virtualenv" \) -prune -o -type f -name "*.py" -not -path "*.tox/*" -print0 | xargs -0 grep -ch "^[[:blank:]]*class.*:" | awk -F":" '{print $(NF)}' | awk '{sum+=$1;} END{print sum;}'

echo
echo "Number of functions:"
echo "===================="
find . -type d \( -name "venv" -o -name ".venv" -o -name ".virtualenv" \) -prune -o -type f -name "*.py" -not -path "*.tox/*" -print0 | xargs -0 grep -ch "^[[:blank:]]*def.*:" | mawk -F":" '{print $(NF)}' | awk '{sum+=$1;} END{print sum;}'
