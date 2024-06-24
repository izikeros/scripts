#!/usr/bin/env bash
# taxbreak.sh
# Provide one month list of changes. Your current dir must be in the git repo.
# Example:
# taxbreak.sh
#
# author: Krystian Safjan (ksafjan@gmail.com)
# Licence MIT

set -Eeuo pipefail

DATE=$(date  +%Y_%m)
# TOMORROW=$(date -d "$1days 13:00" +%Y-%m-%d)
TOMORROW=$(date -d "+1 day" "+%Y-%m-%d")
echo "$TOMORROW"
AUTHOR_NAME="Krystian Safjan"
REPORTS_DIR=$HOME/Documents/copyrights/$DATE
#SINCE='1 month'

FILES_ADDED=$REPORTS_DIR/${DATE}_taxbreak_git_added_files.txt
FILES_ADDED_DOCS=$REPORTS_DIR/${DATE}_taxbreak_added_docs.txt
FILES_MODIFIED_DOCS=$REPORTS_DIR/${DATE}_taxbreak_modified_docs.txt
#FILES_MODIFIED_CODE=$REPORTS_DIR/${DATE}_taxbreak_modified_proj.txt

# ensure that folder for this month reports exists, e.g. for March 2021, folder name should be: 2021_03
echo "Creating folder: $REPORTS_DIR"
mkdir -p $REPORTS_DIR


echo "$HOME/Documents/EY - Added"
find ~/Documents/EY -type f -ctime -30 -exec stat -c "%w %n" {} \; | grep "$(date  +%Y-%m)" | cut -d' ' -f1,4- | tee "$FILES_ADDED_DOCS"

echo "$HOME/Documents/EY - modified"
find ~/Documents/EY -type f -mtime -30 -exec stat -c "%w %n" {} \; | grep "$(date  +%Y-%m)" | cut -d' ' -f1,4- | tee "$FILES_MODIFIED_DOCS"

# for dir in ~/projects/eyproj/*/     # list directories in the "
# do
#     dir=${dir%*/}           # remove the trailing "/"
#     echo "-- ${dir##*/}"    # print everything after the final "/"
# done

# for each project in ~/projects/eyproj check if there are any changes, if so, run git log on that dir and save to file using pattern:
# e.g. for project slider and the reporting fot march 2021: 2021_03_slider_commits.txt
for dir in ~/projects/eyproj/*/     # list directories
do
    dir=${dir%*/}           # remove the trailing "/"
    cd "$dir"
    # check if directory is a git repository
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "-- reading commits from: ${dir##*/}"    # print everything after the final "/"
        FILE_COMMITS=$REPORTS_DIR/${DATE}_${dir##*/}_git_commits.txt
        FILES_ADDED=$REPORTS_DIR/${DATE}_${dir##*/}_git_added_files.txt
        # run git log on that dir and save to file
        # git log --pretty=format:"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]" --decorate --date=short --since="$DATE-01" | grep "$AUTHOR_NAME" | grep "$DATE" > "$FILE_COMMITS"
        echo "- Commits to git repo saved to: $FILE_COMMITS"
        echo "Git added files"
        # git whatchanged --since "${DATE-01}" --until "${TOMORROW}" --oneline --name-status --pretty=format: | sort | uniq | grep ^A | tee "$FILES_ADDED"
    else
        echo "${dir##*/} - Not a git repository, skipping..."
    fi
done


#echo "~/projects/eyproj - modified"
#find ~/projects/eyproj -type f -mtime -30 -exec stat -c "%w %n" {} \; | grep -v '.git' | grep -v '.tox' | grep "$(date  +%Y-%m)" | cut -d' ' -f1,4- >> "$FILES_MODIFIED_CODE"
#echo " - Files added to git repo and ${pwd} folder saved to: $FILES_ADDED"

# echo "Commits..."
# FILE_COMMITS=$HOME/Documents/taxbreak/${DATE}_taxbreak_commits.txt
# git log --pretty=format:"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]" --decorate --date=short --since="$DATE-01" | grep "$AUTHOR_NAME" | grep "$DATE" > "$FILE_COMMITS"
# echo "- Commits to git repo saved to: $FILE_COMMITS"

# echo "Git added files"
# git whatchanged --since "${DATE-01}" --until "${TOMORROW}" --oneline --name-status --pretty=format: | sort | uniq | grep ^A | tee "$FILES_ADDED"

#xdg-open ~/Documents/taxbreak &
