"""
Script that checks if all repos in given location are clean (no uncommitted changes, all commits pushed).

Below is an exemplary implementation of this script in bash:
#!/usr/bin/env bash
#
# Script that provides info on set of repositories
#
# usage:
# 	ron-100-check-if-repos-are-clean.sh dir_to_examine
#
# Examine content of directories in given location
# providing info:
# - repository status: clean | dirty | not repo
# - remote location
# - user name
# TODO: add dir size

# Text color variables
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldblu=${txtbld}$(tput setaf 4) #  blue
bldwht=${txtbld}$(tput setaf 7) #  7-gray, 15-white
bldorg=${txtbld}$(tput setaf 3) #  orange
txtrst=$(tput sgr0)             # Reset

if [ -z "$1" ]; then
	# if no input dir provided add dotfiles and projects/priv
	list=("$HOME"/dotfiles)
	list+=($(ls -d "$HOME"/projects/priv/*))
else
	# otherwise, examine provided dir
	list=$1
fi

# define coloured messages for the status
st_clean="$bldwht[clean ]$txtrst"
st_dirty="$bldred[dirty ]$txtrst"
st_n_git="$bldorg[norepo]$txtrst"

for repo in "${list[@]}"
do
	# echo $repo
	cwd=$(pwd)
	num_commits_text=""
    hosting=""
    repo_col=""
    repo_col=$bldblu$repo$txtrst
    if [ -d "$repo" ]; then
		if [ -d "$repo"/.git ]; then

			cd "$repo" || exit
			# extract hostname from line containing '.git' text
			hosting=$(grep -A2 "origin" .git/config | grep ".git" | grep -v "^\\s.*#" | sed 's/http:\\/\\///' | sed 's/https:\\/\\///' | awk -F"/" '{print $1}' | awk -F":" '{print $1}' | awk -F"=" '{print $2}')

			if [ "$hosting" = " github" ]; then
                hosting=$hosting
            else
                hosting=$bldred$hosting$txtrst
            fi

            # extract user email
			email=$(grep "email" ./.git/config | grep -v "^\\s.*#" | awk -F"=" '{print $2}')

			#echo $hosting
			#grep ".git" ./.git/config
			git status | grep -q "nothing to commit, working tree clean" && st="clean" || st="dirty"
			num_commits=$(git cherry -v | wc -l)

			# repo size
			repo_size=$(du -sh . | tr '\t' ' ' | cut -d' ' -f1)

			if [ "$num_commits" -gt 0 ];then
				num_commits_text=" # $bldred commits to push: $num_commits.$txtrst"
			fi

			# Display text for clean repos
			if [ $st = 'clean' ];then
				status_txt="$st_clean $repo_size $repo_col [$hosting] [$email]"
				echo "[100] $status_txt  $num_commits_text"
			fi

			# Display text for dirty repos
			if [ $st = 'dirty' ];then
		    	status_txt="$st_dirty $repo_size $repo_col"
		    	echo "[100] $status_txt $num_commits_text [$hosting] [$email]"
			fi

		else
			# Display text for non-git repos
			status_txt="$st_n_git $repo_size $repo_col"
			echo "[100] $status_txt $num_commits_text"
		fi
    fi
done
cd "$cwd" || exit

"""

# get list of repositories in given location
import os


def get_repos_from_location(dir_name):
    """
    Get list of repositories in given location.

    Loop over all directories and check if they are git repos. If yes, add to list.
    Args:
        dir_name: directory to examine

    Returns: list of repositories in given location

    """
    repos = []
    for root, dirs, files in os.walk(dir_name):
        for name in dirs:
            if os.path.isdir(os.path.join(root, name, ".git")):
                repos.append(os.path.join(root, name))
    return repos


# extract origin hostname from .git/config, use line containing '.git' text
def get_hosting(repo_dir):
    """
    Get repo url from .git/config.

    extracted repo location can be in the one of the formats:
    - https://github.com/izikeros/Certis.git
    - git@github.com:izikeros
    - github:izikeros
    or can be not defined if there is no remote repo

    Args:
        repo_dir: directory to examine

    Returns: origin hostname
    """
    hosting = ""
    found_origin = False
    with open(os.path.join(repo_dir, ".git", "config")) as f:
        for line in f:
            if line.startswith('[remote "origin"]'):
                found_origin = True
                continue
            if found_origin and line.strip().startswith("url"):
                parts = line.split("=")
                if len(parts) > 1:
                    hosting = parts[1].strip()
                else:
                    hosting = "not defined"
                break
    # remove last part from the repo url. E.g. remove '/filecluster.git' from 'git@github.com:/izikeros/filecluster.git'
    cleaned_hosting = "/".join(hosting.split("/")[:-1])
    return cleaned_hosting

    # with open(os.path.join(repo_dir, ".git", "config"), "r") as f:
    #     for line in f:
    #         if ".git" in line:
    #             return line.split("=")[1].split("/")[0]


def extract_user_email_from_gitconfig(repo_dir):
    """
     Extract user email from .git/config.

    extract user email from .git/config

     Args:
         repo_dir: directory to examine

     Returns: user email
    """
    with open(os.path.join(repo_dir, ".git", "config")) as f:
        for line in f:
            if "email" in line:
                return line.split("=")[1].strip()
    return ""


def check_if_repo_status_is_clean(repo_dir):
    """
    Check if repo status is clean.
    """
    # redirect errors to /dev/null
    return (
        os.system(
            "cd "
            + repo_dir
            + ' && git status | grep -q "nothing to commit, working tree clean" 2>/dev/null'
        )
        == 0
    )


def check_if_there_are_commits_to_push(repo_dir):
    """
    Check if there are commits to push.

    redirect errors to /dev/null
    """
    # FIXME: KS: 2022-08-19: cd generates 0 exit code
    # ignore exit code from cd command
    res = os.system("cd " + repo_dir + "&& git cherry -v 2>/dev/null| wc -l") > 0
    return res


if __name__ == "__main__":
    # expanduser in '~/projects/priv'
    pth = os.path.expanduser("~/projects/priv")
    home = os.path.expanduser("~")
    repos = get_repos_from_location(pth)

    res = []
    for r in repos:
        tup = (
            r.replace(home + "/", "").replace("projects/", " "),
            get_hosting(r),
            extract_user_email_from_gitconfig(r),
            check_if_repo_status_is_clean(r),
            check_if_there_are_commits_to_push(r),
        )
        res.append(tup)
    print(
        "CL CM      HEADER3                                 HEADER4               HEADER5"
    )
    for ele1, ele2, ele3, ele4, ele5 in res:
        print(f"{ele4:<5}{ele5:<5}{ele1:<41}{ele3:<21}{ele2}")
