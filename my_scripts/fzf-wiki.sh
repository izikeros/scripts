#!/usr/bin/env bash
cwd=$(pwd)
cd $HOME/vimwiki || exit
fzf --preview="cat {}" --preview-window=right:70%:wrap
cd $cwd || exit
