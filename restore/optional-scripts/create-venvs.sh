#!/usr/bin/env bash

mkdir -p ~/.venv
cd ~/.venv || exit

pipenv install jupyterlab
