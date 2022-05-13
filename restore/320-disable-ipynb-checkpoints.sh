#!/usr/bin/env bash

ls -l .jupyter/jupyter_notebook_config.py
echo generate config if not exists:
echo jupyter notebook --generate-config
echo edit config file: .jupyter/jupyter_notebook_config.py
echo Add following line to the config:
echo c.FileCheckpoints.checkpoint_dir = \"/tmp/_ipynb_checkpoints\"
