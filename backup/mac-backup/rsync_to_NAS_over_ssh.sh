#!/usr/bin/env bash
# Rsync options used
# -a archive mode (preserve attributes)
# -v verbose
# -z compress
# -h Output numbers in a more human-readable format.
# -m (prune-empty-dirs) This option tells the receiving rsync to get rid of
#    empty directories from the file-list, including nested directories that
#    have no non-directory children.  This is useful for avoiding the creation
#    of a bunch of useless directories when the sending rsync is recursively
#    scanning a hierarchy of files using include/exclude/filter rules.
# -P progress (note that progress info after each )

cd "$HOME" || exit
rsync -avzhm Pictures nas:/share/Multimedia/backups/2023_11_16_mac_before_reformat
rsync -avzhm Desktop nas:/share/Multimedia/backups/2023_11_16_mac_before_reformat
rsync -avzhm Downloads nas:/share/Multimedia/backups/2023_11_16_mac_before_reformat
rsync -avzhm Music nas:/share/Multimedia/backups/2023_11_16_mac_before_reformat
rsync -avzhm Documents nas:/share/Multimedia/backups/2023_11_16_mac_before_reformat
rsync -avzhm Movies nas:/share/Multimedia/backups/2023_11_16_mac_before_reformat
rsync -avzhm projects nas:/share/Multimedia/backups/2023_11_16_mac_before_reformat
rsync -avzhm Transcripts nas:/share/Multimedia/backups/2023_11_16_mac_before_reformat

rsync -avzhm Gramps .keys Sync audiobook bin data .config\
 nas:/share/Multimedia/backups/2023_11_16_mac_before_reformat

rsync -avzhm private nas:/share/Multimedia/backups/2023_11_16_mac_before_reformat