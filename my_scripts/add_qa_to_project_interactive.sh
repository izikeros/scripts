#!/usr/bin/env bash

# requirements-dev.txt
curl -L https://gist.github.com/izikeros/beac1ca8de132ad527ab27e32a950a11/raw -o /tmp/requirements-dev.txt
echo "== requirements-dev.txt =="
read -p "Do you want to add this file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mv /tmp/requirements-dev.txt .
else
	rm /tmp/requirements-dev.txt
fi

# .bandit
curl -L https://gist.github.com/izikeros/4c38eb8ee022eda256a7880ddbd6f834/raw -o /tmp/.bandit
echo "== .bandit =="
read -p "Do you want to add this file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mv /tmp/.bandit .
else
	rm /tmp/.bandit
fi

# mypy.ini
curl -L https://gist.github.com/izikeros/946d65c15190b7cf48590f629119ab60/raw -o /tmp/mypy.ini
echo "== mypy.ini =="
read -p "Do you want to add this file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mv /tmp/mypy.ini .
else
	rm /tmp/mypy.ini
fi

# pre-commit
curl -L https://gist.github.com/izikeros/937b05e81b5dca81d3daf309ea6bad20/raw -o /tmp/.pre-commit-config.yaml
echo "== .pre-commit-config.yaml =="
read -p "Do you want to add this file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mv /tmp/.pre-commit-config.yaml .
else
	rm /tmp/.pre-commit-config.yaml
fi

# pre-commit install
curl -L https://gist.github.com/izikeros/937b05e81b5dca81d3daf309ea6bad20/raw -o /tmp/.pre-commit-config.yaml
read -p "Do you want to install pre-commit package and autoupdate? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    pip install pre-commit
	pre-commit autoupdate
else
	rm /tmp/.pre-commit-config.yaml
fi

# flake8
curl -L https://gist.github.com/izikeros/c938c49f5ad38dcc74a5671e85f694e7/raw -o /tmp/.flake8
echo "== .flake8 =="
read -p "Do you want to add this file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mv /tmp/.flake8 .
else
	rm /tmp/.flake8
fi

# tox.ini
curl -L https://gist.github.com/izikeros/1a2243e083d083c2a4f97cf9c19648d9/raw -o /tmp/tox.ini
echo "== tox.ini =="
read -p "Do you want to add this file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mv /tmp/tox.ini .
else
	rm /tmp/tox.ini
fi

# README.md
curl -L https://gist.github.com/izikeros/87b544d1ba644cc89dccca04fc87d65d/raw -o /tmp/README.md
echo "== README.md =="
read -p "Do you want to add this file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mv /tmp/README.md .
else
	rm /tmp/README.md
fi
