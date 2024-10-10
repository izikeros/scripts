#!/usr/bin/env python3
"""Script that checks if all repos in given location are clean (no uncommitted changes, all commits pushed)."""

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
