#!/usr/bin/env bash

bd="$HOME/backup_nokia"
#bd="/mnt/NAS/backup_nok_2019_03/2"
mkdir -p "$bd"

# # archive settings
echo "Archiving settings"
tar -czvf "$bd/etc.tar.gz" "/etc"
tar -czvf "$bd/settings.tar.gz" "$HOME/bin" "$HOME/polybar-scripts" "$HOME/.ssh" "/etc" "$HOME/Dropbox/vimwiki"
tar -czvf "$bd/vimwiki.tar.gz" "$HOME/Dropbox/vimwiki"
tar -czvf "$bd/redsocks.tar.gz" redsocks.sh redsocks-start.sh redsocks-stop.sh

# # archive all configuration excluding google-chrome
tar -czvf "$bd/config.tar.gz" "$HOME/.config"

# archive media (large directories)
echo "Archiving relevant data"
media_dir_array=("Zotero" "Documents" "projects" "Downloads" "Pictures" "Music" ".recoll_indexes")


for item in ${media_dir_array[*]}
do
    # du -sh $item
    #touch "$bd/$item.tar.gz"
    tar -czvf "$bd/$item.tar.gz" "$HOME/$item"
done

# archive books
tar -czvf "$bd/books_ml.tar.gz" /home/bulk/books/books_ml

# echo "synchronize bookmarks"
# echo "export feeds to Dropbox"
# echo "print installation instructions"
