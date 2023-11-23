#!/usr/bin/env bash

if [[ "$VIRTUAL_ENV" != "" ]]
then

    pip install jupyter
	# pip install jupyterlab

	# Install extensions for Jupyter notebook
	pip install jupyter_contrib_nbextensions

	# Install javascript and css files
	jupyter contrib nbextension install --user

	# for isort extension
	#pip install isort

	# black
	#pip install jupyter-black

	# jupytext
	pip install jupytext

	#jupyter nbextension enable isortformatter/main
	#jupyter nbextension enable codefolding/main

    # downgrade notebook
    pip install notebook==6.1.5 # new version of notebook prevent nbextensions to show up

	# enable TOC2

	# enable collapsible headings

	# isortformatter
	# spellchecker
	# RISE
	# Move selected cells

	# Snippets
else
	echo "No virtualenv found. Please activate your virtualenv and run the script again."
fi
