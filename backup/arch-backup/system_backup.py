# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
#     formats: ipynb,py:percent
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.13.0
#   kernelspec:
#     display_name: coincom
#     language: python
#     name: coincom
# ---

# %%
# #! /usr/bin/env python

import os
import shutil
import time
import re
import argparse
import sys
from sh import rsync, du
from pathlib import Path
import subprocess

# %% [markdown]
# # Backup script

# %% [markdown]
# ## Most important directories and secrets - full copy

# %%
BDIR = "/mnt/NAS/backups/2021_10_22_laptop_hp_selective/"
try:
    os.makedirs(BDIR, exist_ok=True)
except Exception as ex:
    print(f"Root backup dir: {BDIR} failed")
    print(ex)
# TODO: bulk

backup_dirs = {
    "Music": {"enable": True},
    "Documents": {"enable": True},
    "Pictures": {"enable": True},
    "Downloads": {"enable": True},
    "Videos": {"enable": True},
    "data": {"enable": True},
    "bin": {"enable": True},
    "Zotero": {"enable": True},  # perhaps needs copy?
    ".zotero": {"enable": True},
    "projects/misc": {"enable": True},  # misc!!!!
    "projects/priv": {"enable": True},
    "projects/ext": {"enable": True},
    "projects/archive": {"enable": True},
    "projects/Dockerfiles": {"enable": True},
    "projects/wagabunda": {"enable": True},
    "projects/Piotrek": {"enable": True},
    "kdenlive_projects": {"enable": True},
    # misc settings and app data
    #     ".taskrc": {"enable": True},  # taskwarrior file
    ".task": {"enable": True},  # taskwarrior tasks?
    ".stellarium": {"enable": True},
    ".vim": {"enable": True},
    ".vit": {"enable": True},
    ".vscode": {"enable": True},  # vscode extensions
    ".zgen": {"enable": True},
    ".zsh": {"enable": True},
    "exercism": {"enable": True},
    "game": {"enable": True},  # settlers II
    ".local/share": {"enable": True},
    ".atom": {"enable": True},
    ".emacs.d": {"enable": True},
    ".config": {"enable": True},
    ".googleearth": {"enable": True},
    ".ipython": {"enable": True},
    # Gramps
    ".gramps": {"enable": True, "dsc": "Gramps - family tree databases"},
    ".gramps.bak": {"enable": True, "dsc": "Gramps - family tree databases"},
    "Gramps": {"enable": True, "dsc": "Gramps - media, dane, pdf"},
    "safjan_oprzedek_2020-07-31_przed_usunięciem_zajdli.gpkg.media": {
        "enable": True,
        "dsc": "Gramps - stare media (prawdopodobnie nie zmigrowane)",
    },
    "safjan_oprzedek_dynamicweb": {"enable": True, "dsc": "Gramps - jakieś stare"},
    # secrets
    # /home/safjan/projects/priv/coin_commander/.env (binance keys)
    # $HOME/.coinmarketcap-api.key
    ".ssh": {
        "enable": True,
    },
    # msc !!!!!!!!
    "msc": {
        "enable": True,
    },
    ".keys": {
        "enable": True,
    },
    ".google_api_key": {
        "enable": True,
    },
    ".kaggle": {
        "enable": True,
    },
}

backup_dirs = {
    "Documents": {"enable": True},
}
# Prepare output dirs for enabled
USER = "safjan"

# Enabled
DISPLAY_DST = False
for dir_name, dir_conf in backup_dirs.items():
    if dir_conf["enable"]:
        src = os.path.join("/home", USER, dir_name)
        dst = Path(BDIR) / os.path.join("home", USER, dir_name)
        try:
            size = du("-sh", src).split("\t")[0]
        except:
            print(f">>> Cannot read {src}")
        if DISPLAY_DST:
            print(f"{size}\t{dir_name}\tdst: {dst}")
        else:
            print(f"{size}\t{dir_name}")

        os.makedirs(dst, exist_ok=True)

# Disabled
print("---- Disabled ----")
for dir_name, dir_conf in backup_dirs.items():
    if not (dir_conf["enable"]):
        src = os.path.join("/home", USER, dir_name)
        print(f"{size}\t{dir_name}")


# %%
for dir_name, dir_conf in backup_dirs.items():
    if dir_conf["enable"]:
        src = os.path.join("/home", USER, dir_name)
        dst = Path(BDIR) / os.path.join("home", USER, dir_name)
        dst_parrent = dst.parents[0]
        print(f"-- {dir_name} --")
        print(f"dst: {dst_parrent}")
        print(f"=== Starting rsync for: {src}")
        try:
            o = rsync(
                "-ahul",
                "--delete",
                "--no-links",
                "--info=skip0",
                "--exclude=*.tox/*",
                "--exclude=prolog",  # separate job for that (honoring gitignore)
                "--exclude=filecluster", # separate job for that
                "--exclude=slidev-demo",
                "--exclude=Cache",
                src,
                dst_parrent,
            )
            print(o)            
        except ErrorReturnCode as e:
            print(e)


# %% [markdown]
# ## Check backup dir sizes

# %%
for dir_name, dir_conf in backup_dirs.items():
    if dir_conf["enable"]:
        src = os.path.join("/home", USER, dir_name)
        dst = Path(BDIR) / os.path.join("home", USER, dir_name)
        try:
            src_size = du("-sh", src).split("\t")[0]
        except:
            print(f">>> Cannot read {src}")
            
        try:
            dst_size = du("-sh", dst).split("\t")[0]
        except:
            print(f">>> Cannot read {src}")
            
        print(f"{src_size}\t{dst_size}\t{dir_name}")

# %% [markdown]
# ## Most important directories - with honouring .gitignore

# %%
# special approach for projects with heavy gitignores

dirs = [
    (
        "/home/safjan/projects/priv/slidev-demo",
        "/mnt/NAS/backups/2021_10_22_laptop_hp/home/safjan/projects/priv",
    ),
    (
        "/home/safjan/projects/priv/filecluster",
        "/mnt/NAS/backups/2021_10_22_laptop_hp/home/safjan/projects/priv",
    ),
    # misc main project here
]

for src, dst in dirs:
    print(src)
    subprocess.check_output(
        ["rsync", "-ahulv", "--delete", "--filter=:- .gitignore", src, dst]
    )

# %% [markdown]
# ```
#    --archive, -a            archive mode; equals -rlptgoD (no -H,-A,-X)
#    --verbose, -v            increase verbosity
#    --update, -u             skip files that are newer on the receiver
#    -P                       same as --partial --progress       
#    --stats
#    --delete
#    --filter=':- .gitignore'
#    --links, -l              copy symlinks as symlinks
#     
#     add args to exclude
#     "--exclude=lost+found",
#     "--exclude=/sys",
#     "--exclude=/tmp",
#     "--exclude=/proc",
#     "--exclude=/mnt",
#     "--exclude=/dev",
#     "--exclude=/backup",
# ```
