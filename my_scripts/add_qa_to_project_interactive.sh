#!/usr/bin/env bash

# pre-commit
echo "== .pre-commit-config.yaml =="
read -p "Do you want to add this file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    curl -L https://gist.github.com/izikeros/937b05e81b5dca81d3daf309ea6bad20/raw -o ./.pre-commit-config.yaml
fi

# pre-commit install
read -p "Do you want to install pre-commit package and autoupdate? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    pip install pre-commit
	pre-commit autoupdate
fi

# .bandit
echo "== .bandit =="
read -p "Do you want to add this file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	curl -L https://gist.github.com/izikeros/4c38eb8ee022eda256a7880ddbd6f834/raw -o ./.bandit
fi

# mypy.ini
echo "== mypy.ini =="
read -p "Do you want to add this file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	curl -L https://gist.github.com/izikeros/946d65c15190b7cf48590f629119ab60/raw -o ./mypy.ini
fi

# flake8
echo "== .flake8 =="
read -p "Do you want to add this file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    curl -L https://gist.github.com/izikeros/c938c49f5ad38dcc74a5671e85f694e7/raw -o ./.flake8
fi

# tox.ini
echo "== tox.ini =="
read -p "Do you want to add this file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    curl -L https://gist.github.com/izikeros/1a2243e083d083c2a4f97cf9c19648d9/raw -o ./tox.ini
else
	rm /tmp/tox.ini
fi

# pytest.ini
echo "== pytest.ini =="
read -p "Do you want to add this file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    curl -L https://gist.github.com/izikeros/4c79e2f82b68083b8a0b23badc36204d/raw -o ./pytest.ini
fi

# requirements-dev.txt
echo "== requirements-dev.txt =="
read -p "Do you want to add this file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    curl -L https://gist.github.com/izikeros/beac1ca8de132ad527ab27e32a950a11/raw -o ./requirements-dev.txt
else
	rm /tmp/requirements-dev.txt
fi

# README.md
echo "== template README.md =="
read -p "Do you want to add this file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    curl -L https://gist.github.com/izikeros/87b544d1ba644cc89dccca04fc87d65d/raw -o ./README.md
fi

# MIT license
